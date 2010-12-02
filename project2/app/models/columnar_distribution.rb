class ColumnarDistribution < ModelBase
  KeyFieldName = 'id'.freeze
  attr_reader :tables
  
  def initialize(schema)
    super(schema)
    @tables = ColumnarDistribution.generate_tables(@columns, @data_lines)
  end
  
  def create_tables
    @tables.each do |table|
      table.create_table
    end
  end
  
  def drop_tables
    @tables.each do |table|
      table.drop_table
    end
  end
  
  def get_tables_descriptions
    @tables.collect do |table|
      table.get_description
    end
  end
  
  def get_tables_rows_columns
    @tables.collect do |table|
      table.get_data
    end
  end
  
  def load_data
    @tables.each do |table|
      table.load_data
    end
  end
  
  def run_query(query)
  end
  
  private
    # Thanks to http://snippets.dzone.com/posts/show/2390
    def self.create_class(class_name, superclass, &block)
      Object.const_set(class_name, Class.new(superclass, &block))
    end

    def self.generate_tables(columns, data)
      if columns.nil? || columns.empty?
        raise 'No columns given for vertical partitioning'
      end
      column_data = pivot_data(data)
      unless columns.length == column_data.length
        raise 'Did not find values for each column in each row'
      end
      table_schemas = get_table_schemas(columns, column_data)
      get_models(table_schemas)
    end
    
    def self.get_models(schemas)
      return [] if schemas.nil?
      schemas.collect do |table_hash|
        table_name = table_hash[:name]
        class_name = table_name.camelize
        new_class = create_class(class_name, ModelBase) do
          def initialize(schema, table_name)
            super(schema, table_name)
          end
          def create_table
            last_col_name = @columns.last.name
            super(
              sprintf(
                "%s, PRIMARY KEY (%s), UNIQUE index_%s (%s)",
                get_column_definition_string(),
                @columns.first.name,
                last_col_name,
                last_col_name
              )
            )
          end
          def get_data
            ModelBase.get_rows_and_column_names(
              ModelBase.execute(
                sprintf("SELECT * FROM %s", @table_name)
              )
            )
          end
          def get_description
            ModelBase.get_rows_and_column_names(describe())
          end
          def describe
            ModelBase.execute(sprintf("DESCRIBE %s;", @table_name))
          end
          def drop_table
            ModelBase.drop_table(@table_name)
          end
        end
        new_class.new(table_hash[:schema], table_name)
      end
    end
    
    def self.get_table_schemas(columns, column_data)
      column_definitions = column_data.collect do |column_values|
        key_value = 1
        column_values.collect do |col_value|
          col_def = sprintf("%d;%s*", key_value, col_value)
          key_value += 1
          col_def
        end.join
      end
      col_index = 0
      columns.collect do |column|
        table_name = sprintf("%s_%s", KeyFieldName, column.name)
        table_def = sprintf("%s:int(11);%s:%s*%s", KeyFieldName, column.name,
          column.type, column_definitions[col_index])
        col_index += 1
        {:name => table_name, :schema => table_def}
      end
    end
    
    def self.pivot_data(data)
      return [] if data.nil?
      column_data = []
      data.each do |line|
        line.split(';').each_with_index do |col_value, i|
          if i > column_data.length-1
            column_data << []
          end
          # Only append column value if it's not already set to be a row in
          # the new table--part of the point of columnar distribution is to
          # reduce duplication of column values
          unless column_data[i].include?(col_value)
            column_data[i] << col_value
          end
        end
      end
      column_data
    end
end
