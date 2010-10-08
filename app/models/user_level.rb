class UserLevel
  @@rangeRegex = /(\(\d+\)$)|(\(\d,\d\)$)/
  @@nameRegex = /^[a-zA-Z]+[a-zA-Z0-9]+$/
  
  def UserLevel.create_table(schema)
    lines = get_schema_lines(schema)
    columns = lines[0]
    columnDefinitions = []
    columnNames = []
    columns.split(';').each do |columnDef|
      name, type = columnDef.split(':')
      type.downcase!
      if (name =~ @@nameRegex).nil?
        raise "Invalid field name--must be alphanumeric, cannot begin with number"
      end
      if (type =~ @@rangeRegex).nil?
        raise "Invalid field type--no range specified on #{type}"
      end
      unless type.starts_with?('numeric') || type.starts_with?('varchar')
        raise "Invalid field type #{type}--expected only numeric or varchar"
      end
      columnNames << name
      columnDefinitions << "#{name} #{type}"
    end
    if columnDefinitions.length != 2
      raise "Invalid number of columns for user levels table--expected 2"
    end
    ActiveRecord::Base.connection.execute("CREATE TABLE user_levels (
      #{columnDefinitions.join(', ')},
      PRIMARY KEY (#{columnNames.join(', ')})
    );")
  end
  
  def UserLevel.drop_table
    ActiveRecord::Base.connection.execute("DROP TABLE user_levels;")
  end
  
  def UserLevel.get_schema_lines(schema)
    lines = schema.split('*')
    if lines.length < 2
      raise "Invalid user levels table schema, must have at least 2 *-separated lines"
    end
    lines
  end
  
  def UserLevel.load_data(schema)
    lines = get_schema_lines(schema)
    lines.shift # Ignore first line, defines columns
    lines.each do |line|
    end
  end
  
  def UserLevel.table_exists?
    !ActiveRecord::Base.connection.execute(
      "SHOW TABLES WHERE Tables_in_cs505 = 'user_levels'"
    ).fetch_row.nil?
  end
  
  private :get_schema_lines
end
