class ModelBase
  ValueRegex = /^[^"']*$/
  TableNameRegex = /^[^"\-'\s]+$/
  attr_reader :table_name, :schema, :columns, :schema_lines
  
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
    @schema_lines = ModelBase.get_schema_lines(@schema)
    @columns = ModelBase.extract_columns(@schema_lines)
  end
  
  def create_table(table_def)
    execute(
      sprintf("CREATE TABLE %s (%s);", @table_name, table_def)
    )
  end
  
  def drop_table
    execute(sprintf("DROP TABLE IF EXISTS %s;", @table_name))
  end
  
  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end
  
  def ModelBase.extract_columns(lines)
    lines.shift.split(';').collect do |column_def|
      unless column_def.include? ':'
        raise "Invalid table schema line, expected :-separated column name and type"
      end
      name, type = column_def.split(':')
      Column.new(name, type)
    end
  end
  
  def get_queryable_columns
    @columns.select { |col| !col.restricted? }
  end
  
  def ModelBase.get_schema_lines(schema)
    lines = schema.split('*')
    if lines.length < 2
      raise "Invalid table schema, must have at least 2 *-separated lines"
    end
    lines
  end
  
  def load_data
    num_expected_values = @columns.length
    values_to_insert = []
    # Skip first line, contains column definitions
    @schema_lines[1...@schema_lines.length].each do |line|
      unless line.include? ';'
        raise "Invalid value line, expected semi-colon"
      end
      values = line.split(';')
      unless values.length == num_expected_values
        raise "Invalid number of values on line, expected #{num_expected_values}"
      end
      values.each do |value|
        value.strip! # Trim whitespace
        if (ValueRegex =~ value).nil?
          raise "Invalid value, cannot contain quotes"
        end
      end
      values_to_insert << sprintf("'%s'", values.join("', '"))
    end
    execute(sprintf(
      "INSERT INTO %s (%s) VALUES (%s);",
      @table_name,
      @columns.map { |col| col.name }.join(', '),
      values_to_insert.join("), (")
    ))
  end
  
  def table_exists?
    !execute(
      sprintf("SHOW TABLES WHERE Tables_in_cs505 = '%s'", @table_name)
    ).fetch_row.nil?
  end
end
