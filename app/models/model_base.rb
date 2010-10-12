class ModelBase
  ValueRegex = /^[^"']*$/
  TableNameRegex = /^[^"\-'\s]+$/
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
    # In case columns were listed in query as only comma-separated, with no
    # spaces
    if names.length.eql?(1) && names.first.include?(',')
      names.split!(',')
    end
    # Lowercase all the given column names, remove trailing commas
    names.map! { |col_name| col_name.downcase.chomp(',') }
    @columns.select { |col| names.include? col.name }
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
