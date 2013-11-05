require_relative '../config.rb'
require_relative '../Connector.rb'
require_relative '../credit_card/credit_card.rb'
include KeywordProcessor
include Connector

class Person
  attr_accessor :login_name, :first_name, :last_name, :street_address, :city, :state, :zip, :email, :phone, :person_type

  Fields = [:login_name, :password, :first_name, :last_name, :street_address,
    :city, :state, :zip, :email, :phone, :person_type].freeze
  ValidTypes = [:customer, :staff, :manager].freeze

  def Person.drop
    Connector::connect do |c|
      c.query( "DROP TABLE IF EXISTS people;" )
    end
  end

  def Person.exists?( login_name )
    Scaffold.exists?( 'people', 'login_name', login_name )
  end

  def Person.find_all
    Connector::connect do |c|
      results = c.query( 'SELECT * FROM people ORDER BY last_name, first_name ASC;' )

      clean_results( results ) do |row|
        yield row
      end
    end
  end

  def Person.login_form
    str = ''

    unless $session[:user]
      str << '<form method="post" action="' << BaseURI + '/login.cgi">' << "\n"
      str << '<fieldset>' << "\n"
      str << '<legend>Log in</legend>' << "\n"
      str << '<ol>' << "\n"
      str << '<li>' << "\n"
      str << '<label for="name">User name:</label>' << "\n"
      str << '<input type="text" size="20" name="name" id="name" />' << "\n"
      str << '</li>' << "\n"
      str << '<li>' << "\n"
      str << '<label for="password">Password:</label>' << "\n"
      str << '<input type="password" size="20" name="password" id="password" />' << "\n"
      str << '</li>' << "\n"
      str << '<li>' << "\n"
      str << '<input type="submit" value="Log in" /> |' << "\n"
      str << '<a href="' << BaseURI + '/person/new.rhtml">Register &raquo;</a>' << "\n"
      str << '</li>' << "\n"
      str << '</ol>' << "\n"
      str << '</fieldset>' << "\n"
      str << '</form>' << "\n"
    end

    str
  end

  def Person.generate_salt
    require 'base64'
    require 'digest/sha1'
    Base64.encode64( Digest::SHA1.digest( "#{rand(1<<64)}/#{Time.now.to_f}/#{Process.pid}" ) )[0..1]
  end

  def Person.encrypt( plain_text, salt=nil )
    # SQL in plain_text doesn't matter.  SQL in encrypted text matters.
    # Check the output of this function if that is an issue.
    #raise ArgumentContainsSQL if plain_text.contains_sql?

    if salt.nil?
      salt = Person.generate_salt
    end

    encrypted = plain_text.crypt( salt )
  end

  def Person.password_valid?( login_name, password )
    raise ArgumentContainsSQL if login_name.contains_sql?
    return false unless Person.exists?( login_name )
    real_password = nil

    Connector::connect do |c|
      results = c.query( "SELECT password FROM people WHERE login_name='#{login_name}';" )

      hash = results.fetch_hash
      real_password = hash['password']
    end

    salt = real_password[0..1]
    crypt_password = Person.encrypt( password, salt )
    return false unless crypt_password == real_password
    true
  end

  def Person.find( login_name )
    return nil if login_name.nil?
    raise ArgumentContainsSQL if login_name.contains_sql?

    Connector::connect do |conn|
      result = conn.query( "SELECT * FROM people WHERE login_name='#{login_name}'" )

      return nil if 1 != result.num_rows
      hash = result.fetch_hash
      hash[:login_name] = login_name
      found_person = Person.new( hash )

      # TODO: Make a method to get cart from database and
      # store in person instance.  Require login to do this?
      #found_person.retrieve_cart

      return found_person
    end
  end

  def Person.create( args={} )
    # Generate new encrypted passwords until we get one that doesn't
    # contain SQL
    if args[:password]
      encrypted_password = Person.encrypt( args[:password] )

      while encrypted_password.contains_sql?
        encrypted_password = Person.encrypt( args[:password] )
      end

      args[:password] = encrypted_password
    end

    person = Person.new( args )
    values = []

    # Create a string of table fields, separated by commas, based
    # on the @fields variable set in #new
    field_list = Fields.map( &:to_s ).join( ', ' )

    Fields.each { |field| values << "'#{args[field]}'" }
    value_list = values.join( ', ' )

    Connector::connect do |c|
      # Insert into the table fields listed in field_list
      # the values in value_list
      c.query( "INSERT INTO people (#{field_list}) VALUES (#{value_list});" )
    end

    person
  end


  # Used to create a person object; does NOT insert it into the database
  def initialize( args={}.freeze )
    defaults = {
      :login_name => :MANDATORY,
      :password => :MANDATORY,
      :first_name => :MANDATORY,
      :last_name => :MANDATORY,
      :street_address => :MANDATORY,
      :city => :MANDATORY,
      :state => :MANDATORY,
      :zip => :MANDATORY,
      :email => :MANDATORY,
      :phone => 'NULL',
      :person_type => :customer
    }

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
  end

  def Person.change_password( login_name, old_pw, new_pw )
    return nil unless Person.password_valid?( login_name, old_pw )
    new_pw_crypt = Person.encrypt( new_pw )

    while new_pw_crypt.contains_sql?
      new_pw_crypt = Person.encrypt( new_pw )
    end

    Connector::connect do |conn|
      conn.query( "UPDATE people
                   SET password='#{new_pw_crypt}'
                   WHERE login_name='#{login_name}';" )
    end
  end

  # Get an array of credit card objects from the database (possibly empty)
  def Person.credit_cards( login_name )
    CreditCard.find_by_login_name( login_name )
  end

  def Person.delete( login )
    raise ArgumentContainsSQL if login.contains_sql?
    result = nil
    Connector::connect do |conn|
      result = conn.query( "DELETE FROM people WHERE login_name = '#{login}';" )
    end
    result
  end

  def Person.populate
    hashes = []

    hashes << {
      :login_name=>'test_customer', :password=>'g00g13', :first_name=>'John',
      :last_name=>'Doe', :street_address=>'456 Some Road',
      :city=>"Lexington", :state=>"KY",
      :zip=>"40508", :email=>"john@yahoo.com", :phone=>"234-456-6789",
      :person_type=>"customer"
    }

    hashes << {
      :login_name=>'test_staff', :password=>'g00g13', :first_name=>'Jane',
      :last_name=>'Doe', :street_address=>'123 A Street',
      :city=>'Dallas', :state=>'TX', :zip=>'90210',
      :email=>'jane@gmail.com', :phone=>'123-456-7890',
      :person_type=>'staff'
    }

    hashes << {
      :login_name=>'test_manager', :password=>'g00g13', :first_name=>'Jim',
      :last_name=>'Beam', :street_address=>'815 Lala Terrace',
      :city=>'Beverly Hills', :state=>'CA', :zip=>'90210',
      :email=>'jim@hotmail.com', :phone=>'111-222-3333',
      :person_type=>'manager'
    }

    hashes.each { |hash| Person.create( hash ) }
  end

  # drop person table and create it again
  def Person.reset
    Person.drop

    Connector::connect do |c|
      c.query( "CREATE TABLE people(
                login_name      VARCHAR(#{MaxStringLength}) NOT NULL,
                password        VARCHAR(#{MaxStringLength}) NOT NULL,
                first_name      VARCHAR(#{MaxStringLength}) NOT NULL,
                last_name       VARCHAR(#{MaxStringLength}) NOT NULL,
                street_address VARCHAR(#{MaxStringLength}) NOT NULL,
                city            VARCHAR(#{MaxStringLength}) NOT NULL,
                state           CHAR(#{StateLength})        NOT NULL,
                zip             VARCHAR(#{ZipCodeLength})   NOT NULL,
                email           VARCHAR(#{MaxStringLength}) NOT NULL,
                phone           VARCHAR(#{MaxStringLength}),
                person_type     ENUM('customer', 'staff', 'manager') NOT NULL,
                PRIMARY KEY (login_name)
               );" )
    end

    Person.populate
  end

  def Person.update( login_name, args )
    Scaffold.update( 'people', "login_name='#{login_name}'", args )
  end
end
