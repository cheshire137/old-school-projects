# Represents the clients table and provides methods for creating, dropping, and
# populating the table.
class Client < ModelBase
  TableName = "clients"
  
  # Constructor.  Will create a new Client instance.  Interprets the given
  # schema.
  def initialize(schema)
    super(TableName, schema) # Call base constructor
    check_classification_columns()
  end
  
  # Creates the clients table based on the schema given in the class
  # constructor, but does not load any data into the table.
  def create_table
    # Don't know what kind of PRIMARY KEY would work because user could give
    # any kind of table schema, unlike with user_levels table where two
    # columns are required.
    super(get_column_definition_string())
  end
  
  # Returns a MySQL result set describing the clients table.
  def Client.describe
    ModelBase.execute(sprintf("DESCRIBE %s;", TableName))
  end
  
  # Drops the clients table.
  def Client.drop_table
    super(TableName)
  end
  
  # Runs the given query from the perspective of the given user, implementing
  # polyinstantiation.  Does not run the given query directly but instead
  # generates a similar query that respects the classification level of the
  # given user.
  def run_query(user_name, query)
    # Check arguments
    if user_name.nil? || user_name.blank?
      raise "Invalid user name, cannot be nil or blank"
    end
    if (user_name =~ ValueRegex).nil?
      raise "Invalid user name, cannot contain quotes"
    end
    if query.nil? || query.blank?
      raise "Invalid query, cannot be nil or blank"
    end
    
    query.strip! # Remove trailing whitespace
    words = query.split # Split on whitespace
    check_query_words(words)
    
    # Ensure the user said 'FROM' in the query
    from_index = words.index { |word| word.downcase.eql? 'from' }
    if from_index.nil?
      raise "Invalid query, must contain one FROM keyword"
    end
    
    # Get columns from the columns list in this table, based on the user-given
    # column names in the query
    queried_columns = get_columns_by_name(words[1...from_index])
    check_queried_columns(queried_columns)
    
    # Even though we're going to ignore the table name they gave, we still
    # want the user to have given a well-formed query
    table_name_index = from_index+1
    if words.length < table_name_index
      raise "Invalid query, no table name specified"
    end

    # Ensure user isn't trying to query from the secret user classification
    # levels table
    table_name = words[table_name_index]
    if table_name.downcase.eql? 'user_levels'
      raise "Invalid query, cannot query user classification table"
    end
    
    # Everything checks out, so construct a query that will respect the given
    # user's classification level while getting the data requested in the
    # given query.
    query = sprintf(
      "SELECT %s
FROM clients,
     (
       SELECT class
       FROM user_levels
       WHERE name = '%s'
     ) AS user_level
%s",
      get_case_statements(queried_columns), # Get CASE ... END statements
      user_name,
      words[from_index+2...words.length].join(' ') # Last part of the query
    )
    
    # Get the results of the query as an array of hashes
    nice_rows, column_names = ModelBase.get_rows_and_column_names(
      ModelBase.execute(query)
    )
    
    # Return the generated query, the results of executing that query, and the
    # column names
    [query, nice_rows, column_names]
  end
  
  # Returns true if the clients table exists in the database.
  def Client.table_exists?
    super(TableName)
  end
  
  # All methods below this will be private to this class
  private
    # Ensures there are classification columns for each regular column in the
    # table, as is necessary for attribute-level polyinstantiation.
    def check_classification_columns
      # Get the names of all columns
      given_col_names = @columns.map(&:name)
      
      # Get the names for all the expected classification columns
      expected_class_col_names =
        @columns.map(&:get_class_column).reject { |col_name| col_name.nil? }
      
      # Ensure all the expected classification columns are part of the table
      expected_class_col_names.each do |col_name|
        unless given_col_names.include? col_name
          raise sprintf(
            "Invalid table schema, expected classification column %s",
            col_name
          )
        end
      end
    end
  
    # Checks the given array of Column instances to ensure no classification
    # columns were queried.
    def check_queried_columns(queried_columns)
      valid_column_names = get_queryable_columns().map(&:name)
      queried_columns.each do |column|
        unless valid_column_names.include? column.name
          raise sprintf("Invalid column '%s' in query, only %s allowed",
            column.name,
            valid_column_names.join(', '))
        end
      end
    end
    
    # Checks the given array of words found in a user-given query to ensure
    # a query was given, it's a SELECT query, and it has only one SELECT...FROM
    # block (i.e., is a simple query).
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
    
    # This will return a string of CASE...END statements for the given array of
    # Column instances.  The CASE statements ensure NULL is returned if the
    # classification of a queried column is too high.
    def get_case_statements(queried_columns)
      # Iterate over all queried columns...
      queried_columns.collect do |column|
        # Get the name of the classification column for the current column,
        # e.g., lclass for column lname.
        class_column = column.get_class_column()
        
        # If the current column has a function applied to it, such as COUNT,
        # we need to structure things differently.
        if column.function.nil?
          func_start = ''
          func_end = ''
          selected_name = column.name
        else
          func_start = column.function + '('
          func_end = ')'
          selected_name = sprintf(
            "%s(%s)",
            column.function,
            column.name
          )
        end
        
        # Return a string of the comma-separated CASE statements
        sprintf(
          "%s CASE WHEN %s = class OR
                  class = 'TS' OR
                  (class = 'S' AND (%s = 'C' OR %s = 'U')) OR
                  (class = 'C' AND %s = 'U')
             THEN %s
             ELSE NULL
        END %s AS \"%s\"",
          func_start,
          class_column,
          class_column,
          class_column,
          class_column,
          column.name,
          func_end,
          selected_name
        )
      end.join(",\n       ")
    end
end
