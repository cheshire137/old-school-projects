require_relative '../scaffold.rb'

class CreditCard < Scaffold
  attr_accessor :login_name, :first_name, :last_name, :number, :company, :expiration_month, :expiration_year, :street_address, :city, :state, :zip

  Companies = ['Discover', 'Visa', 'Mastercard', 'American Express'].sort.freeze

  Fields = [:login_name, :first_name, :last_name, :number, :company,
            :expiration_month, :expiration_year, :street_address,
            :city, :state, :zip].freeze

  def initialize( args={}.freeze )
    defaults = {
      :login_name => :MANDATORY,
      :first_name => :MANDATORY,
      :last_name => :MANDATORY,
      :number => :MANDATORY,
      :company => :MANDATORY,
      :expiration_month => :MANDATORY,
      :expiration_year => :MANDATORY,
      :street_address => :MANDATORY,
      :city => :MANDATORY,
      :state => :MANDATORY,
      :zip => :MANDATORY
    }

    args.each do |key, value|
      raise "Argument '#{key}' contains SQL" if key.to_s.contains_sql?
      raise "Value '#{value}' for Argument '#{key}' contains SQL" if value.to_s.contains_sql?
    end

    # Use the keyword processor to merge the default values for
    # this method's arguments with those that were actually
    # passed in; this will also raise an exception if an arg.
    # marked :MANDATORY in defaults above was left out
    args = process_args( args, defaults )

    # Go through each of the arguments given and create a
    # class variable of their key name (e.g. @isbn, @price)
    # set to the given value or the default value for that
    # argument if none was specified
    args.each do |key, value|
      eval "@#{key} = args[:#{key}]"
    end
  end # initialize


  def CreditCard.create( args={} )
    card = CreditCard.new( args )

    # Create a string of table fields, separated by commas, based
    # on the @fields variable set in #new
    field_list = Fields.map( &:to_s ).join( ', ' )

    values = []

    Fields.each do |field|
      values << "'#{args[field]}'"
    end

    value_list = values.join( ', ' )

    Connector::connect do |c|
      # Insert into the table fields listed in field_list
      # the values in value_list
      c.query( "INSERT INTO credit_cards (#{field_list}) VALUES (#{value_list});")
    end
    card
  end # CreditCard.create


  # Update the credit card information by submitting the changes to
  # the database, then querying the database to rebuild the CreditCard object
  # based on the stored data.
  def update( args={}.freeze )

    # Array that will contain strings of the form key = new_value.
    changes = []

    args.each do |key, value|
      raise ArgumentContainsSQL, "Key '#{key}' contains SQL" if key.to_s.contains_sql?
      raise ArgumentContainsSQL, "Value '#{value}' with key '#{key}' contains SQL" if value.to_s.contains_sql?

      # Put quotes around all strings except NULL, since it is a MySQL keyword.
      if value.class == String and value.to_s.upcase != "NULL"
        changes << "#{key} = '#{value}'"

      # Allow value to be nil for convenience
      elsif value.nil?
        changes << "#{key} = NULL"

      # Pass numeric values or NULL as they are
      else
        changes << "#{key} = #{value}"

      end # if value.class == String and ...
    end # args.each

    changes_list = changes.join( ', ' )

    Connector::connect do |conn|
      conn.query( "UPDATE credit_cards
                  SET #{changes_list}
                  WHERE login_name = '#{@login_name}'
                        and number = '#{@number}';"
                )
    end

    # Find this person in the database and create a new person object
    # that contains all of the updated information.  We don't simply
    # change instance variables, since the changes might not have
    # been made successfully.
    self.refresh
  end # update

  # Find this card in the database and update the instance variables to match
  # what is stored in the database
  def refresh
    result = nil

    Connector::connect do |conn|
      result = conn.query( "SELECT * FROM credit_cards
                            WHERE login_name ='#{@login_name}'
                                  and number = '#{@number}';" )
    end

    return nil if nil == result or 1 != result.num_rows

    result.fetch_hash.each do |key, value|
      if value.class == String
        eval "@#{key} = '#{value}'"

      elsif value
        eval "@#{key} = #{value}"

      else
        eval "@#{key} = nil"  # NULL value was stored in table

      end # if value.class == String
    end # result.fetch_hash.each
  end # refresh



  # I'm not sure this method makes sense for credit cards...
  # See CreditCard.find_by_login_name()
  def CreditCard.find( number )
    Scaffold.find( 'credit_cards', 'number', number.to_s )
  end


  # Finds all credit cards belonging to the given person.
  # Returns an array containing the credit card objects that were found.
  # If a block is given, it yields the found rows one-by-one
  def CreditCard.find_by_login_name( login_name )
    if login_name.to_s.contains_sql?
      raise ArgumentContainsSQL, "Login name '#{login_name}' contains SQL"
    end

    result = nil
    card_array = []

    Connector::connect do |conn|
      results = conn.query("SELECT * FROM credit_cards
                           WHERE login_name='#{login_name}';")

      return [] if results.nil?

      # Fill the return array
      results.each do |result| # yields an array of values for the columns
      # in the order they were specified when the table was created
        result_hash = {}

        # Each element in the res array corresponds to an element in
        # the Fields array
        Fields.each_with_index do |field, index|
          curr_result = results[index]

          if curr_result.class == String
            result_hash[field] = "#{curr_result}"
          elsif curr_result
            result_hash[field] = curr_result
          end
        end

        # Append the new CreditCard to the array to return
        card_array << CreditCard.new( result_hash )
      end

      # if block is given, yield each row found to the block
      if block_given?
        clean_results( result ) do |row|
          yield row
        end
      end

      card_array
    end
  end # CreditCard.find_by_login_name


  # Yield each row of the credit_cards table in sequence
  def CreditCard.find_all
    Connector::connect do |c|
      results = c.query( 'SELECT * FROM credit_cards;' )

      clean_results( results ) do |row|
        yield row

      end # clean_results
    end # Connector::connect
  end # CreditCard.find_all


  def CreditCard.delete( login_name, number )
    raise ArgumentContainsSQL, "Login name '#{login_name}' contains SQL" if login_name.contains_sql?
    raise ArgumentContainsSQL, "Credit card number '#{number}' contains SQL" if number.contains_sql?
    result = nil
    Connector::connect do |conn|
      result = conn.query( "DELETE FROM credit_cards
                            WHERE login_name = '#{login_name}'
                                  and number = '#{number}';"
                          )
    end # Connector::connect
    result
  end # CreditCard.delete


  def CreditCard.drop
    Connector::connect do |c|
      c.query( "DROP TABLE IF EXISTS credit_cards;" )
    end
  end


  # drop credit cards table and create it again (leaving
  # it empty)
  def CreditCard.reset
    CreditCard.drop
    companies_list = Companies.collect do |name|
      "'#{name}'"
    end.join( ', ' )

    # Primary key is customer login name and number, since one card could
    # be listed for multiple accounts and one person might have multiple
    # cards stored in the system
    Connector::connect do |conn|
      conn.query( "CREATE TABLE credit_cards(
                   login_name VARCHAR(#{MaxStringLength}) NOT NULL,
                   first_name VARCHAR(#{MaxStringLength}) NOT NULL,
                   last_name VARCHAR(#{MaxStringLength}) NOT NULL,
                   number CHAR(#{CreditCardLength}) NOT NULL,
                   company ENUM(#{companies_list}) NOT NULL,
                   expiration_month INT NOT NULL,
                   expiration_year INT NOT NULL,
                   street_address VARCHAR(#{MaxStringLength}) NOT NULL,
                   city VARCHAR(#{MaxStringLength}) NOT NULL,
                   state CHAR(   #{StateLength}) NOT NULL,
                   zip VARCHAR(#{ZipCodeLength}) NOT NULL,
                   PRIMARY KEY (login_name, number)
                 );" )
    end # Connector::connect
  end # CreditCard.reset



  @@TestHash = {  :login_name => "TEST_LOGIN_NAME", :first_name => "test first",
                  :last_name => "test last", :number => "1234567890123456", :company => "test company",
                  :expiration_month => "12", :expiration_year => "2008", :street_address => "test addy 1",
                  :city => "test city", :state => "KY", :zip => "00000"
               }

  # Test the operation of the CreditCard class by calling several functions with
  # test data
  # 1. Search database for previous test data
  # 2. Delete previous test data from database
  # 3. Create a test entry in the database
  # 4. Perform several updates to the test entry, each testing what should be a legal value
  def CreditCard.test
    #result = nil
    #Connector::connect do |conn|
    #  result = conn.query("SELECT * FROM credit_cards
    #                      WHERE login_name = '#{@@TestHash[:login_name]}'
    #                            and number = '#{@@TestHash[:number]}';")
    #end
    #if result != nil and result.num_rows > 0
    #  CreditCard.delete( @@TestHash[:login_name], @@TestHash[:number] )
    #end

    # Test return value of CreditCard.find_by_login_name
    test_card_list = CreditCard.find_by_login_name( @@TestHash[:login_name] )
    if test_card
      CreditCard.delete( test_card_list.first.login_name, test_card_list.first.number )
      test_card = nil
    end

    # Reinsert test card and test CreditCard.find_by_login_name with block
    test_card = CreditCard.create( @@TestHash )

    CreditCard.find_by_login_name( @@TestHash[:login_name] ) do |card|
      CreditCard.delete( card.login_name, card.number )
    end

    # Reinsert test card and test CreditCard#update with legal operations
    test_card = CreditCard.create( @@TestHash )

    # Leave entry in the database to verify the result if so desired.
  end # CreditCard.test
end
