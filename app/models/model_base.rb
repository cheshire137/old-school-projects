class ModelBase
  ValueRegex = /^[^"']*$/
  TableNameRegex = /^[^"\-'\s]+$/
  Classifications = ['U', 'C', 'S', 'TS']
  attr_reader :table_name, :schema, :columns, :data_lines
  
  def initialize(table_name, schema)
    if table_name.nil? || table_name.blank?
      raise "Invalid table name, cannot be nil or blank"
    end
    if (TableNameRegex =~ table_name).nil?
      raise "Invalid table name, cannot contain quotes, hyphens, or spaces"
    end
    if schema.nil? || schema.blank?
      raise "Invalid table schema, cannot be nil or blank"
    end
    @table_name = table_name
    @schema = schema
    @data_lines = ModelBase.get_schema_lines(@schema)
    @columns = ModelBase.extract_columns(@data_lines.shift)
  end
  
  def create_table(table_def)
    ModelBase.execute(
      sprintf("CREATE TABLE %s (%s);", @table_name, table_def)
    )
  end
  
  def drop_table
    ModelBase.drop_table(@table_name)
  end
  
  def ModelBase.drop_table(table_name)
    execute(sprintf("DROP TABLE IF EXISTS %s;", table_name))
  end
  
  def ModelBase.execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
  
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
    
    if selected_cols.length != names.length
      names.each do |name|
        # Check if user applied function to this column:
        if name.include?('(') && name.include?(')')
          func_start = name.index('(')
          name_only = name[func_start+1...name.index(')')]
          matching_columns = @columns.select { |col| col.name.eql? name_only }
          next if matching_columns.length != 1
          column = matching_columns.first.dup
          function = name[0...func_start]
          column.function = function
          selected_cols << column
        end
      end
    end
    
    selected_cols
  end
  
  def get_queryable_columns
    @columns.select { |col| !col.restricted? }
  end
  
  def ModelBase.get_schema_lines(schema)
    lines = schema.split('*')
    if lines.length < 2
      raise "Invalid table schema, must have at least 2 *-separated lines"
    end
    lines.select { |line| !line.nil? && !line.strip.blank? }
  end
  
  def load_data
    num_expected_values = @columns.length
    values_to_insert = []
    @data_lines.each do |line|
      unless line.include? ';'
        raise "Invalid value line, expected semi-colon"
      end
      values = line.split(';')
      unless values.length == num_expected_values
        raise "Invalid number of values on line, expected #{num_expected_values}"
      end
      cur_values_to_insert = ""
      values.each_with_index do |value, index|
        value.strip! # Trim whitespace
        if (ValueRegex =~ value).nil?
          raise "Invalid value, cannot contain quotes"
        end
        column = @columns[index]
        cur_values_to_insert << if column.numeric?
          # Don't quote numeric values, remove commas
          value.gsub(/,/, '')
        else
          sprintf("'%s'", value)
        end
        if index < num_expected_values-1
          cur_values_to_insert << ', '
        end
      end
      values_to_insert << cur_values_to_insert
    end
    ModelBase.execute(sprintf(
      "INSERT INTO %s (%s) VALUES (%s);",
      @table_name,
      @columns.map { |col| col.name }.join(', '),
      values_to_insert.join("), (")
    ))
  end
  
  def table_exists?
    !ModelBase.execute(
      sprintf("SHOW TABLES WHERE Tables_in_cs505 = '%s'", @table_name)
    ).fetch_row.nil?
  end
  
  protected
    def get_classification_column_definition(column_name)
      sprintf("%s ENUM('%s') NOT NULL DEFAULT '%s'", column_name,
        Classifications.join("', '"), Classifications.first)
    end
    
    def get_column_definition_string
      @columns.map do |column|
        if column.restricted?
          get_classification_column_definition(column.name)
        else
          sprintf("%s %s", column.name, column.type)
        end
      end.join(', ')
    end
end
