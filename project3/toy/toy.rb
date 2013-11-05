require_relative '../scaffold.rb'

class Toy < Scaffold
  attr_accessor :name, :upc, :price, :quantity, :manufacturer
  Fields = [:name, :upc, :price, :quantity, :manufacturer].freeze

  def Toy.drop
    Connector::connect do |c|
      c.query( "DROP TABLE IF EXISTS toys;" )
    end
  end

  def Toy.find( upc )
    Scaffold.find( 'toys', 'upc', upc.to_s )
  end

  def Toy.find_all
    Connector::connect do |c|
      results = c.query( 'SELECT * FROM toys ORDER BY name ASC;' )

      clean_results( results ) do |row|
        yield row
      end
    end
  end

  def Toy.find_by( field, string, &block )
    Scaffold.find_by( 'toys', field, string, Fields, &block )
  end

  def Toy.create( args={}.freeze )
    toy = Toy.new( args )

    # Create a string of table fields, separated by commas, based
    # on the @fields variable set in #new
    field_list = Fields.map( &:to_s ).join( ', ' )

    Connector::connect do |c|
      # Insert into the table fields listed in field_list
      # the values in value_list
      c.query( "INSERT INTO toys (#{field_list}) VALUES (
                  '#{toy.name}', '#{toy.upc}', #{toy.price}, #{toy.quantity},
                  '#{toy.manufacturer}'
                );")
    end

    toy
  end

  def initialize( args={}.freeze )
    defaults = {
      :name => :MANDATORY,
      :upc => :MANDATORY,
      :price => 0,
      :quantity => 0,
      :manufacturer => :MANDATORY
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

    # Ensure price is a float
    args[:price] = args[:price].to_f

    # Ensure quantity is an integer
    args[:quantity] = args[:quantity].to_i

    # Go through each of the arguments given and create a
    # class variable of their key name (e.g. @isbn, @price)
    # set to the given value or the default value for that
    # argument if none was specified
    args.each do |key, value|
      eval "@#{key} = args[:#{key}]"
    end
  end

  # Generates a random 12-digit UPC
  def Toy.generate_upc
    upc = ''
    12.times { upc << rand( 9 ).to_s }
    upc
  end

  def Toy.delete( upc )
    raise "UPC '#{upc}' contains SQL" if upc.contains_sql?
    Connector::connect do |conn|
      conn.query( "DELETE FROM toys WHERE upc = '#{upc}';" )
    end
  end

  def Toy.method_missing( symbol, *args )
    if symbol.to_s =~ /^find_by_(\w+)$/i
      field = $1.to_sym
      raise "Invalid field #{field}" unless Fields.include?( field )
      Toy.find_by( field, args ) { |row| yield row }
    else
      super
    end
  end

  def Toy.populate
    names = ['Barbie', 'Legos', 'Troll doll', 'G.I. Joe', 'Teenage Mutant Ninja Turtles Pizza-Throwing Van', 'ball', 'building blocks', 'Wii', 'Xbox 360', 'Playstation 3', 'Paper Mario', 'Paper Mario:  Thousand Year Door', 'The Sims 2', 'Super Paper Mario']
    manufacturers = ['Nintendo', 'Mattel', 'Fisher Price', 'Hasbro', 'Bandai', 'Tiger', 'Lego', 'Galoob', 'Playmobil', 'Toymax']
    num_manufacturers = manufacturers.size - 1

    names.each do |name|
      manufacturer = manufacturers[rand( num_manufacturers )]
      upc = Toy.generate_upc
      price = Scaffold.generate_price( 50 )
      quantity = rand( 100 )
      quantity += 1 if quantity == 0
      Toy.create( :name => name, :manufacturer => manufacturer, :upc => upc, :price => price, :quantity => quantity )
    end
  end

  def Toy.search_form
    searchable_fields = ['name', 'manufacturer']
    str = ''
    str << <<END
<form action="#{BaseURI}/search.cgi" method="post">
<input type="hidden" name="product_type" value="toy" />
  <fieldset>
    <legend>Search Toys</legend>
    <ol>
      <li>
        <label for="query">Query:</label>
        <input type="text" size="20" name="query" id="query" />
      </li>
      <li>
        <label for="field">Field:</label>
        <select name="field" id="field">
END

    searchable_fields.each do |field|
      str << '<option name="field" value="' << field + '">'
      str << field.capitalize + '</option>' << "\n"
    end

    str << <<END
        </select>
      </li>
      <li><input type="submit" value="Search &raquo;" /></li>
    </ol>
  </fieldset>
</form>
END
  end

  # drop toys table and create it again
  def Toy.reset
    Toy.drop

    Connector::connect do |c|
      c.query( "CREATE TABLE toys(
                 name         VARCHAR(#{MaxStringLength}) NOT NULL,
                 upc          CHAR(#{UPCLength})          NOT NULL,
                 price        FLOAT                       NOT NULL,
                 quantity     INT                         NOT NULL,
                 manufacturer VARCHAR(#{MaxStringLength}) NOT NULL,
                 PRIMARY KEY (upc)
                );" )
    end

    Toy.populate
  end

  def Toy.exists?( upc )
    Scaffold.exists?( 'toys', 'upc', upc )
  end

  def Toy.update( upc, args={}.freeze )
    raise "Invalid UPC given: '#{upc}'" if upc.nil? || upc.to_s.blank?
    Scaffold.update( 'toys', "upc='#{upc}'", args )
  end
end
