class UserLevel < ModelBase
  TableName = "user_levels"
  
  def initialize(schema)
    super(TableName, schema)
    if @columns.length != 2
      raise "Invalid number of columns for user levels table, expected 2"
    end
    class_columns = @columns.select { |col| col.name.eql? 'class' }
    unless class_columns.length.eql? 1
      raise "Invald schema, expected one column named 'class'"
    end
  end
  
  def create_table
    super(sprintf("%s, PRIMARY KEY (%s)",
      @columns.map { |col| "#{col.name} #{col.type}" }.join(', '),
      @columns.map { |col| col.name }.join(', ')
    ))
  end
  
  def UserLevel.describe
    ModelBase.execute(sprintf("DESCRIBE %s;", TableName))
  end
  
  def UserLevel.drop_table
    super(TableName)
  end
end
