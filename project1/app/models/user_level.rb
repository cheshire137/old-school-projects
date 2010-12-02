# Represents the user_levels table and provides methods for creating, dropping,
# and populating it.
class UserLevel < ModelBase
  TableName = "user_levels"
  
  # Constructor taking a table schema.  Expects a 'class' column to be defined
  # in the schema.
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
  
  # Creates the user_levels table using the schema given in the constructor.
  def create_table
    super(
      sprintf(
        "%s, PRIMARY KEY (%s)",
        get_column_definition_string(),
        @columns.map(&:name).join(', ')
      )
    )
  end
  
  # Returns a MySQL result set describing the user_levels table.
  def UserLevel.describe
    ModelBase.execute(sprintf("DESCRIBE %s;", TableName))
  end
  
  # Drops the user_levels table.
  def UserLevel.drop_table
    super(TableName)
  end
  
  # Returns true if the user_levels table exists in the database.
  def UserLevel.table_exists?
    super(TableName)
  end
end
