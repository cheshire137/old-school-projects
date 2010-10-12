class Client < ModelBase
  def initialize(schema)
    super("clients", schema)
    given_col_names = @columns.map(&:name)
    expected_class_col_names =
      @columns.map(&:get_class_column).reject { |col_name| col_name.nil? }
    expected_class_col_names.each do |col_name|
      unless given_col_names.include? col_name
        raise sprintf(
          "Invalid table schema, expected classification column %s",
          col_name
        )
      end
    end
  end
  
  def create_table
    # Don't know what kind of PRIMARY KEY would work because user could give
    # any kind of table schema, unlike with user_levels table where two
    # columns are required.
    super(sprintf("%s",
      @columns.map { |col| "#{col.name} #{col.type}" }.join(', ')
    ))
  end
  
  def run_query(user_name, query)
    if user_name.nil? || user_name.blank?
      raise "Invalid user name, cannot be nil or blank"
    end
    if (user_name =~ ValueRegex).nil?
      raise "Invalid user name, cannot contain quotes"
    end
    if query.nil? || query.blank?
      raise "Invalid query, cannot be nil or blank"
    end
    query.strip!
    words = query.split # Split on whitespace
    check_query_words(words)
    from_index = words.index { |word| word.downcase.eql? 'from' }
    if from_index.nil?
      raise "Invalid query, must contain one FROM keyword"
    end
    queried_columns = get_columns_by_name(words[1...from_index])
    check_queried_columns(queried_columns)
    if words.length < from_index+1
      raise "Invalid query, no table name specified"
    end
    query = sprintf(
      "SELECT %s
       FROM clients,
            (
              SELECT UPPER(class) AS class
              FROM user_levels
              WHERE name = '%s'
            ) AS user_level
       %s",
      get_case_statements(queried_columns),
      user_name,
      words[from_index+2...words.length].join(' ') # Append the last of user-given query
    )
    execute(query)
  end
  
  private
    def check_queried_columns(queried_columns)
      valid_columns = get_queryable_columns()
      queried_columns.each do |column|
        unless valid_columns.include? column
          raise sprintf("Invalid column '%s' in query, only %s allowed",
            column.name,
            valid_columns.map(&:name).join(', '))
        end
      end
    end
    
    def check_query_words(words)
      if words.empty?
        raise "Invalid query, must have spaces or newlines"
      end
      unless words.first.downcase.eql? 'select'
        raise "Invalid query, SELECT queries allowed only"
      end
      if words.select { |word| word.downcase.eql? 'from' }.length > 1
        raise "Invalid query, can only contain one SELECT ... FROM block"
      end
    end
    
    def get_case_statements(queried_columns)
      queried_columns.collect do |column|
        class_column = column.get_class_column()
        sprintf(
          "CASE WHEN %s = class OR
                     class = 'TS' OR
                     (class = 'S' AND %s = 'C')
                THEN %s
                ELSE NULL
           END AS %s",
          class_column,
          class_column,
          column.name,
          column.name
        )
      end.join(', ')
    end
end
