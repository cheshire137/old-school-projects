# This class contains shared functionality for UserLevel and Client.
class ModelBase
  ValueRegex = /^[^"']*$/
  TableNameRegex = /^[^"\-'\s]+$/
  Classifications = ['U', 'C', 'S', 'TS']
  attr_reader :table_name, :schema, :columns, :data_lines
  
  # Constructor taking a table name and a schema.  This will extract Column
  # instances from the schema as well as the lines of data for the table, though
  # no data will be added to the table in MySQL until #load_data is called.
  def initialize(table_name, schema)
    # Check parameters
    if table_name.nil? || table_name.blank?
      raise "Invalid table name, cannot be nil or blank"
    end
    if (TableNameRegex =~ table_name).nil?
      raise "Invalid table name, cannot contain quotes, hyphens, or spaces"
    end
    if schema.nil? || schema.blank?
      raise "Invalid table schema, cannot be nil or blank"
    end
    
    # Store the given data in member variables.
    @table_name = table_name
    @schema = schema
    
    # Extract the data from the given schema.  This data will later be stored
    # in the MySQL table when #load_data is called.
    @data_lines = ModelBase.get_schema_lines(@schema)
    
    # Extract Column instances based on the first line of the schema.
    @columns = ModelBase.extract_columns(@data_lines.shift)
  end
  
  # Class method that will drop a table with the given name if it exists.
  def ModelBase.drop_table(table_name)
    execute(sprintf("DROP TABLE IF EXISTS %s;", table_name))
  end
  
  # Class method that executes the given SQL statement.
  def ModelBase.execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
  
  # Loads data into the MySQL table.  Uses the data in the schema given in the
  # constructor.
  def load_data
    num_expected_values = @columns.length
    values_to_insert = []
    
    # Iterate over each line given in the table schema that contains data to be
    # stored in the table
    @data_lines.each do |line|
      unless line.include? ';'
        raise "Invalid value line, expected semi-colon"
      end
      values = line.split(';')
      unless values.length == num_expected_values
        raise "Invalid number of values on line, expected #{num_expected_values}"
      end
      cur_values_to_insert = ""
      
      # Iterate over all values defined on this line
      values.each_with_index do |value, index|
        value.strip! # Trim whitespace
        if (ValueRegex =~ value).nil?
          raise "Invalid value, cannot contain quotes"
        end
        
        # Get the column into which this particular value will be inserted
        column = @columns[index]
        
        cur_values_to_insert << if column.numeric?
          # Don't quote numeric values, remove commas
          value.gsub(/,/, '')
        else
          sprintf("'%s'", value)
        end
        
        # Append separating comma to the list of values to insert, if necessary
        if index < num_expected_values-1
          cur_values_to_insert << ', '
        end
      end
      
      # Append values for the current row to the array of all rows
      values_to_insert << cur_values_to_insert
    end
    
    # Run the INSERT statement, which inserts multiple rows of data
    ModelBase.execute(sprintf(
      "INSERT INTO %s (%s) VALUES (%s);",
      @table_name,
      @columns.map(&:name).join(', '),
      values_to_insert.join("), (")
    ))
  end
  
  # Methods below this will be protected, accessible to this class and its
  # child classes.
  protected
    # Creates a table with the given table definition.
    def create_table(table_def)
      ModelBase.execute(
        sprintf("CREATE TABLE %s (%s);", @table_name, table_def)
      )
    end
  
    # Drops the table from the database.
    def drop_table
      ModelBase.drop_table(@table_name)
    end
  
    # Returns a MySQL column definition string for the given column name.
    def ModelBase.get_classification_column_definition(column_name)
      sprintf("%s ENUM('%s') NOT NULL DEFAULT '%s'", column_name,
        Classifications.join("', '"), Classifications.first)
    end
    
    # Returns a MySQL column definition string for all columns in the table.
    def get_column_definition_string
      @columns.map do |column|
        if column.restricted?
          ModelBase.get_classification_column_definition(column.name)
        else
          sprintf("%s %s", column.name, column.type)
        end
      end.join(', ')
    end
    
    def get_columns_by_name(names)
      if names.nil? || names.empty?
        return []
      end
      if names.length.eql? 1
        name = names.first
        if name.include? ','
          # In case columns were listed in query as only comma-separated, with no
          # spaces
          names.split!(',')
        elsif name.eql? '*'
          # User querying all columns, so return all non-classification columns
          return @columns.select { |col| !col.restricted? }
        end
      end
      # Lowercase all the given column names, remove trailing commas
      names.map! { |col_name| col_name.downcase.chomp(',') }
      
      # Select from all valid columns those that the user SELECTed:
      selected_cols = @columns.select { |col| names.include? col.name }
      
      # If we didn't get a Column for each of the names given, maybe the user
      # applied aggregate functions to some of them.
      if selected_cols.length != names.length
        names.each do |name|
          # Check if user applied function to this column:
          if name.include?('(') && name.include?(')')
            func_start = name.index('(')
            name_only = name[func_start+1...name.index(')')]
            
            # Ensure the column to which the function was applied is an actual
            # column in the table before we proceed.
            matching_columns = @columns.select { |col| col.name.eql? name_only }
            next if matching_columns.length != 1
            
            # Copy the matching Column instance before we go setting its
            # function property.
            column = matching_columns.first.dup
            function = name[0...func_start]
            column.function = function
            
            # Append this Column to the array of columns we'll return
            selected_cols << column
          end
        end
      end
      
      # Return array of Column instances
      selected_cols
    end
    
    # Returns all Column instances for this table that are not classification
    # columns.
    def get_queryable_columns
      @columns.select { |col| !col.restricted? }
    end
  
  # All methods below this will be private to this class.
  private
    # Class method that will return an array of Column instances based on the
    # given string of column definitions.
    def ModelBase.extract_columns(column_defs_line)
      if column_defs_line.nil? || column_defs_line.blank?
        raise "Invalid column definitions line, cannot be nil or blank"
      end
      column_defs_line.split(';').collect do |column_def|
        unless column_def.include? ':'
          raise "Invalid table schema line, expected :-separated column name and type"
        end
        name, type = column_def.split(':')
        Column.new(name, type)
      end
    end
    
    # Class method that will parse the given schema and return all non-nil,
    # non-blank lines.  Lines are separated by an asterisk.
    def ModelBase.get_schema_lines(schema)
      lines = schema.split('*')
      if lines.length < 2
        raise "Invalid table schema, must have at least 2 *-separated lines"
      end
      lines.select { |line| !line.nil? && !line.strip.blank? }
    end
end
