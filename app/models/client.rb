class Client < ModelBase
  def initialize(schema)
    super("clients", schema)
  end
  
  def create_table
    # Don't know what kind of PRIMARY KEY would work because user could give
    # any kind of table schema, unlike with user_levels table where two
    # columns are required.
    super(sprintf("%s",
      @columns.map { |col| "#{col.name} #{col.type}" }.join(', ')
    ))
  end
  
  def run_query(query)
    if query.nil? || query.blank?
      raise "Invalid query, cannot be nil or blank"
    end
    query.trim!
    words = query.split # Split on whitespace
    check_query_words(words)
    from_index = words.index { |word| word.downcase.eql? 'from' }
    if from_index.nil?
      raise "Invalid query, must contain one FROM keyword"
    end
    queried_columns = words[1...from_index]
    check_queried_columns(queried_columns)
    # Swap user-queried columns with *, putting user-queried columns in outer
    # query and * in inner query, so we can check user classifications in outer
    # query
  end
  
  private
    def check_queried_columns(queried_columns)
      valid_columns = get_queryable_columns().map { |col| col.name }
      queried_columns.each do |column_name|
        column_name.chomp!(',') # Remove ending comma, if it's there
        column_name.downcase! # Lowercase
        unless valid_columns.include? column_name
          raise sprintf("Invalid column '%s' in query, only %s allowed",
            column_name,
            valid_columns.join(', '))
        end
      end
    end
    
    def check_query_words(words)
      if words.empty?
        raise "Invalid query, must have spaces or newlines"
      end
      unless words.first.downcase.equal? 'select'
        raise "Invalid query, SELECT queries allowed only"
      end
      if words.select { |word| word.downcase.eql? 'from' }.length > 1
        raise "Invalid query, can only contain one SELECT ... FROM block"
      end
    end
end
