class ColumnarDistribution < ModelBase
  KeyFieldName = 'key'.freeze
  attr_reader :tables
  
  def initialize(schema)
    super(schema)
    @tables = ColumnarDistribution.generate_tables(@columns, @data_lines)
    raise @tables.inspect
  end
  
  def drop_tables
    @tables.each do |table|
      table.send(:drop_table)
    end
  end
  
  private
    def ColumnarDistribution.generate_tables(columns, data)
      if columns.nil? || columns.empty?
        raise 'No columns given for vertical partitioning'
      end
      column_data = pivot_data(data)
      unless columns.length == column_data.length
        raise 'Did not find values for each column in each row'
      end
      table_schemas = get_table_schemas(columns, column_data)
    end
    
    def ColumnarDistribution.get_table_schemas(columns, column_data)
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
        table_def = sprintf("%s:numeric(11);%s:%s*%s", KeyFieldName, column.name,
          column.type, column_definitions[col_index])
        col_index += 1
        table_def
      end
    end
    
    def ColumnarDistribution.pivot_data(data)
      column_data = []
      unless data.nil?
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
      end
      column_data
    end
end
