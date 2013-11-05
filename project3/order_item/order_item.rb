require_relative '../config.rb'
require_relative '../Connector.rb'
include KeywordProcessor
include Connector

class OrderItem
  attr_accessor :order_id, :product_id, :product_type, :price, :quantity
  Fields = [:order_id, :product_id, :product_type, :price, :quantity].freeze

  def OrderItem.delete( order_id, product_id, product_type )
    Connector::connect do |c|
      c.query( "DELETE FROM order_items
                WHERE order_id=#{order_id} AND
                product_id='#{product_id}' AND
                product_type='#{product_type}';" )
    end
  end

  def OrderItem.drop
    Connector::connect do |c|
      c.query( "DROP TABLE IF EXISTS order_items;" )
    end
  end

  def OrderItem.find( order_id, product_id, product_type )
    raise "Product ID '#{product_id}' contains SQL" if product_id.contains_sql?
    raise "Product type '#{product_type}' contains SQL" if product_type.contains_sql?

    Connector::connect do |c|
      result = c.query( "SELECT * FROM order_items
                         WHERE order_id=#{order_id} AND
                         product_id='#{product_id}' AND
                         product_type='#{product_type}';" )
      return clean_result( result )
    end
  end

  def OrderItem.find_all_by_isbn( isbn )
    raise 'ISBN contains SQL' if isbn.contains_sql?

    Connector::connect do |c|
      people_fields = [:first_name, :last_name, :street_address, :city, :state, :zip, :email, :phone, :person_type].collect do |field|
        "people.#{field}"
      end.join( ', ' )

      fields = "order_items.price,
                order_items.quantity,
                orders.time,
                orders.status,
                orders.login_name,
                #{people_fields}"

      tables = 'order_items
                LEFT OUTER JOIN orders
                ON order_items.order_id=orders.id
                LEFT OUTER JOIN books
                ON order_items.product_id=books.isbn
                LEFT OUTER JOIN people
                ON orders.login_name=people.login_name'

      results = c.query( "SELECT #{fields} FROM #{tables}
                          WHERE order_items.product_type='book'
                          AND books.isbn='#{isbn}'
                          ORDER BY orders.time ASC;" )

      hash = results.fetch_hash

      if hash.nil?
        yield( nil, [] )
      else
        fields = hash.keys
        clean_results( results ) { |row| yield( row, fields ) }
      end
    end
  end

  def OrderItem.find_all_by_login_name( login_name )
    raise "Login name contains SQL" if login_name.contains_sql?

    Connector::connect do |c|
      book_fields = [:isbn, :title, :author, :publisher].collect do |field|
        "books.#{field}"
      end.join( ', ' )

      toy_fields = [:name, :upc, :manufacturer].collect do |field|
        "toys.#{field}"
      end.join( ', ' )

      fields = "#{book_fields},
                #{toy_fields},
                order_items.price,
                order_items.quantity,
                orders.time,
                orders.status,
                orders.login_name"

      tables = 'order_items
                LEFT OUTER JOIN orders
                ON order_items.order_id=orders.id
                LEFT OUTER JOIN people
                ON orders.login_name=people.login_name
                LEFT OUTER JOIN toys
                ON toys.upc=order_items.product_id
                LEFT OUTER JOIN books
                ON books.isbn=order_items.product_id'

      results = c.query( "SELECT #{fields} FROM #{tables}
                          WHERE people.login_name='#{login_name}'
                          ORDER BY orders.time, books.title, toys.name ASC;" )

      hash = results.fetch_hash

      if hash.nil?
        yield( nil, [] )
      else
        fields = hash.keys
        clean_results( results ) { |row| yield( row, fields ) }
      end
    end
  end

  def OrderItem.find_all_by_upc( upc )
    raise 'UPC contains SQL' if upc.contains_sql?

    Connector::connect do |c|
      people_fields = [:first_name, :last_name, :street_address, :city, :state, :zip, :email, :phone, :person_type].collect do |field|
        "people.#{field}"
      end.join( ', ' )

      fields = "order_items.price,
                order_items.quantity,
                orders.time,
                orders.status,
                orders.login_name,
                #{people_fields}"

      tables = 'order_items
                LEFT OUTER JOIN orders
                ON order_items.order_id=orders.id
                LEFT OUTER JOIN toys
                ON order_items.product_id=toys.upc
                LEFT OUTER JOIN people
                ON orders.login_name=people.login_name'

      results = c.query( "SELECT #{fields} FROM #{tables}
                          WHERE order_items.product_type='toy'
                          AND order_items.product_id='#{upc}'
                          ORDER BY orders.time ASC;" )

      hash = results.fetch_hash

      if hash.nil?
        yield( nil, [] )
      else
        fields = hash.keys
        clean_results( results ) { |row| yield( row, fields ) }
      end
    end
  end

  def OrderItem.find_all_by_order( order_id )
    return [] unless Order.exists?( order_id )

    Connector::connect do |c|
      results = c.query( "SELECT * FROM order_items
                          WHERE order_id=#{order_id};" )

      clean_results( results ) do |row|
        yield row
      end
    end
  end

  def OrderItem.create( args={}.freeze )
    item = OrderItem.new( args )

    # Create a string of table fields, separated by commas, based
    # on the @fields variable set in #new
    field_list = Fields.map( &:to_s ).join( ', ' )

    Connector::connect do |c|
      # Insert into the table fields listed in field_list
      # the values in value_list
      c.query( "INSERT INTO order_items (#{field_list}) VALUES (
                  #{item.order_id}, #{item.product_id}, '#{item.product_type}',
                  #{item.price}, #{item.quantity}
                );")
    end

    item
  end

  def initialize( args={} )
    defaults = {
      :order_id => :MANDATORY,
      :product_id => :MANDATORY,
      :product_type => :MANDATORY,
      :price => :MANDATORY,
      :quantity => 1
    }

    args.each do |key, value|
      raise "Argument '#{key}' contains SQL" if key.to_s.contains_sql?
      raise "Value '#{value}' for key '#{key}' contains SQL" if value.to_s.contains_sql?
    end

    unless Order.exists?( args[:order_id] )
      raise "Invalid order: order ##{args[:order_id]} does not exist"
    end

    # Use the keyword processor to merge the default values for
    # this method's arguments with those that were actually
    # passed in; this will also raise an exception if an arg.
    # marked :MANDATORY in defaults above was left out
    args = process_args( args, defaults )

    args[:price] = args[:price].to_f
    args[:quantity] = args[:quantity].to_i

    # Go through each of the arguments given and create a
    # class variable of their key name (e.g. @isbn, @price)
    # set to the given value or the default value for that
    # argument if none was specified
    args.each do |key, value|
      eval "@#{key} = args[:#{key}]"
    end
  end
  def OrderItem.reset
    Connector::connect do |c|
      OrderItem.drop

      c.query( "CREATE TABLE order_items(
                order_id     INT NOT NULL,
                product_id   VARCHAR(#{MaxStringLength}) NOT NULL,
                product_type ENUM('book', 'toy') NOT NULL,
                price        FLOAT,
                quantity     INT,
                PRIMARY KEY (order_id, product_id, product_type)
              );" )
    end
  end

  def OrderItem.update( order_id, product_id, product_type, args={}.freeze )
    conditions = "order_id=#{order_id} AND product_id='#{product_id}' AND product_type='#{product_type}'"
    Scaffold.update( 'order_items', conditions, args )
  end
end
