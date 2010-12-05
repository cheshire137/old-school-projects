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
    if query.nil? || query.blank?
      raise "Invalid query, cannot be nil or blank"
    end
    
    query.strip! # Remove trailing whitespace
    query.chomp!(';') # Remove trailing semicolon
    words = query.split # Split on whitespace
    from_index = check_query_words(words)
    
    # Even though we're going to ignore the table name they gave, we still
    # want the user to have given a well-formed query
    table_name_index = from_index+1
    if words.length < table_name_index
      raise "Invalid query, no table name specified"
    end
    
    # Get Columns from the Columns list in this table, based on the user-given
    # column names in the query
    raw_selected_cols = words[1...from_index]
    selected_cols = get_columns_by_name(raw_selected_cols)
    tables_used = get_necessary_tables(selected_cols)
    query_remainder = words[from_index+2...words.length]
    where_block = ColumnarDistribution.get_where_block(tables_used,
      query_remainder)

    # Everything checks out, so construct a query that uses the vertically
    # partitioned tables to get the user-requested data
    query = sprintf(
      "SELECT %s
FROM %s
%s",
      get_columns_block(selected_cols),
      tables_used.map(&:table_name).join(', '),
      where_block
    )
    result = ModelBase.execute(query)
    
    # Get the results of the query as an array of hashes
    rows_and_columns = ModelBase.get_rows_and_column_names(result)
    
    # Return the generated query, the results of executing that query, and the
    # column names
    [query, rows_and_columns[:rows], rows_and_columns[:columns]]
  end
  
  private
    def get_columns_block(columns)
      columns.collect do |column|
        col_name = column.name
        col_func = column.function
        if col_func.nil?
          func_start = ''
          func_end = ''
          selected_name = col_name
        else
          func_start = col_func + '('
          func_end = ')'
          selected_name = sprintf("%s(%s)", col_func, col_name)
        end
        func_start + col_name + func_end
      end.join(",\n       ")
    end
  
    # Checks the given array of words found in a user-given query to ensure
    # a query was given, it's a SELECT query, and it has only one SELECT...FROM
    # block (i.e., is a simple query).
    def check_query_words(words)
      if words.empty?
        raise "Invalid query, must have spaces or newlines"
      end
      unless words.first.downcase == 'select'
        raise "Invalid query, SELECT queries allowed only"
      end
      condition = lambda { |word| word.downcase == 'from' }
      if words.select(&condition).length > 1
        raise "Invalid query, can only contain one SELECT ... FROM block"
      end
      from_index = words.index(&condition)
      if from_index.nil?
        raise "Invalid query, must contain one FROM keyword"
      end
      from_index
    end
    
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
            drop_table()
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
            hash = ModelBase.get_rows_and_column_names(
              ModelBase.execute(
                sprintf("SELECT * FROM %s", @table_name)
              )
            )
            hash.merge({:title => @table_name})
          end
          def get_description
            hash = ModelBase.get_rows_and_column_names(describe())
            hash.merge({:title => @table_name})
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
    
    def get_necessary_tables(selected_cols)
      if selected_cols.nil? || selected_cols.empty?
        raise "Invalid query, no columns were SELECTed"
      end
      selected_cols.collect do |column|
        table_regex = /_#{column.name}$/
        table = @tables.find { |tbl| !(tbl.table_name =~ table_regex).nil? }
        if table.nil?
          raise "Invalid query: #{column.name} is not a valid column"
        end
        table
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
    
    def self.get_where_block(tables, query_remainder)
      table_names_keys = tables.collect do |table|
        sprintf("%s.%s", table.table_name, KeyFieldName)
      end
      
      # If we have tables a, b, c, we end up with table_pairs = [[a, b], [b, c]]
      # for joining purposes
      tables_offset = table_names_keys - [table_names_keys.first]
      table_pairs = (table_names_keys - [table_names_keys.last]).zip(tables_offset)
      
      # Get a string like a.id=b.id AND b.id=c.id
      table_join = table_pairs.collect do |table_pair|
        table_pair.join('=')
      end.join(" AND\n      ")
      
      # User didn't give any WHERE, GROUP BY, or ORDER BY clauses, so we can
      # just return our table-joining WHERE clause
      if query_remainder.nil? || query_remainder.empty?
        return 'WHERE ' + table_join
      end
      
      query_length = query_remainder.length;
      lowercase_query = query_remainder.map(&:downcase)
      group_index, group_order_by = get_group_info(lowercase_query,
        query_remainder, query_length)
      where_clause = get_user_where_clause(lowercase_query, query_remainder,
        query_length, table_join, group_index)
      sprintf("WHERE %s\n%s", where_clause, group_order_by)
    end
    
    def self.get_group_info(lowercase_query, query_remainder, query_length)
      group_index = lowercase_query.index { |word| 'group' == word }
      if group_index.nil?
        group_order_by = ''
      else
        by_index = group_index + 1
        if query_length <= by_index || lowercase_query[by_index] != 'by'
          raise "Invalid query, found GROUP key word but not GROUP BY"
        end
        group_order_by = query_remainder[group_index...query_length].join(' ')
      end
      [group_index, group_order_by]
    end
    
    def self.get_user_where_clause(lowercase_query, query_remainder,
      query_length, table_join, group_index)
      where_index = lowercase_query.index { |word| 'where' == word }
      return table_join if where_index.nil?
      first_condition_index = where_index + 1
      if query_length <= first_condition_index
        raise "Invalid query, found WHERE key word but no clause"
      end
      if group_index.nil?
        last_where_index = query_length
      else
        last_where_index = group_index
      end
      user_where = query_remainder[first_condition_index...last_where_index].join(' ')
      sprintf("%s AND
      (%s)", table_join, user_where)
    end
end
