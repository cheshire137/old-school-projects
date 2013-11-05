require 'config.rb'
require 'Connector.rb'
include KeywordProcessor
include Connector

class Scaffold
  def Scaffold.find( table, field, value )
    raise "Field '#{field}' contains SQL" if field.contains_sql?

    if value.respond_to?( :contains_sql? ) && value.contains_sql?
      raise "Argument '#{value}' for field '#{field}' contains SQL"
    end

    if [Fixnum, Float].include?( value.class )
      conditions = "#{field}=#{value}"
    else
      conditions = "#{field}='#{value}'"
    end

    Connector::connect do |c|
      result = c.query( "SELECT * FROM #{table}
                         WHERE #{conditions} LIMIT 1;" )
      return clean_result( result )
    end
  end

  def Scaffold.find_by( table, field, value, valid_fields )
    raise "Argument '#{value}' contains SQL" if value.to_s.contains_sql?
    raise "Invalid field '#{field}'" unless valid_fields.include?( field.to_sym )
    query = "'%#{value.to_s}%'"

    Connector::connect do |c|
      results = c.query( "SELECT * FROM #{table} WHERE #{field} LIKE #{query}" )

      clean_results( results ) do |row|
        yield row
      end
    end
  end

  def Scaffold.exists?( table, field, value, type=:string )
    return false if value.nil?

    if value.respond_to?( :contains_sql? ) && value.contains_sql?
      raise "Value &ldquo;#{value}&rdquo; contains SQL"
    end

    Connector::connect do |conn|
      query = "SELECT * FROM #{table} WHERE #{field}="

      if type == :string || type == :date || type == :datetime
        query << "'#{value}'"
      else
        query << value.to_s
      end

      result = conn.query( query )
      return true if result.num_rows > 0
    end

    false
  end

  # Generates a random price as a float, based on the given maximum
  # dollar value
  def Scaffold.generate_price( max_dollars=100 )
    dollars = rand( max_dollars ).to_i
    cents_arr = [0, 50, 99]
    num_cents = cents_arr.size - 1
    cents = cents_arr[rand( num_cents )]
    "#{dollars}.#{cents}".to_f
  end

  def Scaffold.update( table, conditions, args )
    # Array that will contain strings of the form key = new_value.
    changes = []

    raise "Table name '#{table}' contains SQL" if table.contains_sql?

    args.each do |key, value|
      raise "Key '#{key}' contains SQL" if key.to_s.contains_sql?
      raise "Value '#{value}' with key '#{key}' contains SQL" if value.to_s.contains_sql?

      # Put quotes around all strings except NULL, since it is a
      # MySQL keyword.
      if value.class == String and value.to_s.upcase != "NULL"
        changes << "#{key}='#{value}'"

      # Allow value to be nil for convenience
      elsif value.nil?
        changes << "#{key}=NULL"

      # Pass numeric values as they are
      else
        changes << "#{key}=#{value}"
      end
    end

    changes_list = changes.join( ', ' )

    Connector::connect do |conn|
      conn.query( "UPDATE #{table}
                   SET #{changes_list}
                   WHERE #{conditions};" )
    end
  end
end
