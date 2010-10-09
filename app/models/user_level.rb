class UserLevel < ModelBase
  def initialize(schema)
    super("user_levels", schema)
    if @columns.length != 2
      raise "Invalid number of columns for user levels table, expected 2"
    end
  end
  
  def create_table
    create_table(sprintf("%s, PRIMARY KEY (%s)",
      @columns.map { |col| "#{col.name} #{col.type}" }.join(', '),
      @column_names.join(', ')
    ))
  end
end
