require_relative '../scaffold.rb'

class Order < Scaffold
  attr_accessor :login_name, :status, :id, :time
  Fields = [:login_name, :status, :id, :time].freeze

  def Order.create( args={}.freeze )
    order = Order.new( args )

    # Create a string of table fields, separated by commas, based
    # on the @fields variable set in #new
    field_list = Fields.map( &:to_s ).join( ', ' )

    Connector::connect do |c|
      # Insert into the table fields listed in field_list
      # the values in value_list
      c.query( "INSERT INTO orders (#{field_list}) VALUES (
                  '#{order.login_name}', '#{order.status}',
                  #{order.id}, '#{order.time}'
                );")
    end

    order
  end

  def Order.delete( id )
    id = id.to_i

    Connector::connect do |c|
      c.query( "DELETE FROM orders WHERE id=#{id};" )
    end
  end

  def initialize( args={}.freeze )
    defaults = {
      :login_name => :MANDATORY,
      :status     => 'in_progress',
      :id         => Connector::get_next_auto_increment( 'orders' ),
      :time       => Connector::get_time
    }

    args.each do |key, value|
      raise "Argument '#{key}' contains SQL" if key.to_s.contains_sql?
      raise "Value '#{value}' for key '#{key}' contains SQL" if value.to_s.contains_sql?
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
  end

  def Order.get( login_name, status, limit=1 )
    raise "Login name '#{login_name}' contains SQL" if login_name.contains_sql?
    raise "Status '#{status}' contains SQL" if status.contains_sql?

    Connector::connect do |c|
      query = "SELECT * FROM orders WHERE login_name='#{login_name}' AND status='#{status}'"

      unless limit == :no_limit
        query << " LIMIT #{limit}"
      end

      query << ';'
      results = c.query( query )

      if (limit == :no_limit || limit > 1) && block_given?
        clean_results( results ) do |row|
          yield row
        end
      else
        return clean_result( results )
      end
    end
  end

  def Order.get_completed( login_name, &block )
    Order.get( login_name, 'completed', :no_limit, &block )
  end

  def Order.get_in_progress( login_name )
    Order.get( login_name, 'in_progress' )
  end

  def Order.exists?( id )
    Scaffold.exists?( 'orders', 'id', id, :int )
  end

  def Order.find( id )
    Scaffold.find( 'orders', 'id', id.to_i )
  end


  def Order.drop
    Connector::connect do |c|
      c.query( "DROP TABLE IF EXISTS orders;" )
    end
  end

  def Order.has_items?( id )
    id = id.to_i

    Connector::connect do |c|
      result = c.query( "SELECT * FROM order_items
                         WHERE order_id=#{id};" )
      return true if result.num_rows > 0
    end

    false
  end

  # drop orders table and create it again (leaving it
  # empty)
  def Order.reset
    Connector::connect do |c|
      Order.drop

      c.query( "CREATE TABLE orders(
                login_name  VARCHAR(#{Connector::MaxStringLength}) NOT NULL,
                id          INT NOT NULL AUTO_INCREMENT,
                status      ENUM('in_progress', 'completed') NOT NULL,
                time        DATETIME,
                PRIMARY KEY (id)
              );" )
    end
  end
  def Order.update( id, args={}.freeze )
    Scaffold.update( 'orders', "id=#{id}", args )
  end
end
