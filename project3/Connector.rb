#!/usr/bin/ruby
require 'mysql'

module Connector
  # completely arbitrary
  MaxStringLength = 100.freeze

  # 5 digits + 4 digit extension + dash between if we like
  ZipCodeLength = 10.freeze

  # State abbreviations, e.g. KY
  StateLength = 2.freeze

  # Number of digits in a credit card
  CreditCardLength = 16.freeze

  # Number of digits in a standard UPC number
  UPCLength = 12.freeze

  # ISBN numbers were recently increased in length from 10 to 13
  ISBNLength = 13.freeze

  class Row
    attr_accessor :fields

    def create_method( name, &block )
      self.class.send( :define_method, name, &block )
    end

    # Returns the value of the primary key
    def id
      field_names = @fields.map( &:name ).map( &:to_sym )

      if field_names.include? :isbn
        @isbn
      elsif field_names.include? :upc
        @upc
      else
        nil
      end
    end

    def initialize( fields, hash )
      @fields = fields
      field_names = hash.keys

      # Create an attr_accessor for each field in this row
      field_names.each { |field| self.class.send( :attr_accessor, field ) }

      hash.each do |field, value|
        if field =~ /id$/ || field == 'quantity'
          self.instance_eval "@#{field} = #{value.to_i}"
        elsif field == 'price'
          self.instance_eval "@#{field} = #{value.to_f}"
        else
          self.instance_eval "@#{field} = '#{value}'"
        end
      end
    end
  end

  def clean_result( result )
    fields = result.fetch_fields
    hash = result.fetch_hash

    if hash.nil?
      nil
    else
      Row.new( fields, hash )
    end
  end

  def clean_results( results )
    fields = results.fetch_fields
    results.each_hash { |hash| yield Row.new( fields, hash ) }
  end

  def connect(
    host='mysql.cs405.3till7.net',
    user='cs405',
    password='p0w3rb00k',
    database='cs405'
  )
    begin
      connection = Mysql::new( host, user, password, database )
      
      if block_given?
        yield connection
        connection.close
      else
        return connection
      end
    rescue Mysql::Error => e
      puts "Error code:\t#{e.errno}"
      puts "Error message:\t#{e.error}"
      puts "Error SQLSTATE:\t#{e.sqlstate}" if e.respond_to?( 'sqlstate' )
    end
  end

  # Returns the value that the next row inserted into the given
  # table will get for their AUTO_INCREMENT field
  def get_next_auto_increment( table )
    raise "Table &ldquo;#{table}&rdquo; contains SQL" if table.contains_sql?

    connect do |c|
      results = c.query( "SHOW TABLE STATUS LIKE '#{table}';" )
      rows = []
      clean_results( results ) { |row| rows << row }
      return rows.first.Auto_increment.to_i
    end
  end

  def get_time
    require 'date'
    time = Time.now
    date = Date.civil( time.year, time.month, time.day ).to_s
    time = "#{time.hour}:#{time.min}:#{time.sec}"
    "#{date} #{time}"
  end

  # Lists all tables in the database and returns their names in an
  # array
  def list_tables
    tables = []

    connect do |c|
      result = c.query( "SHOW TABLES;" )

      while row = result.fetch_row do
        puts row[0]
        tables << row[0]
      end
    end

    tables
  end
  
  def drop_all_tables
    Toy.drop
    CreditCard.drop
    Book.drop
    Order.drop
    Person.drop
  end
        
  # BIG RED BUTTON.  Drops all tables then creates them again
  def reset_all_tables
    Toy.reset
    CreditCard.reset
    Book.reset
    Order.reset
    Person.reset
  end
end
