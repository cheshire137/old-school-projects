require '/home/tom_mcknight/cs405.3till7.net/scaffold.rb'

class Book < Scaffold
  attr_accessor :isbn, :price, :quantity, :title, :author, :publisher
  Fields = [:isbn, :price, :quantity, :title, :author, :publisher].freeze

  def Book.drop
    Connector::connect do |c|
      c.query( "DROP TABLE IF EXISTS books;" )
    end
  end

  def Book.find( isbn )
    Scaffold.find( 'books', 'isbn', isbn.to_s )
  end

  def Book.find_all
    Connector::connect do |c|
      results = c.query( 'SELECT * FROM books ORDER BY title ASC;' )

      clean_results( results ) do |row|
        yield row
      end
    end
  end

  def Book.find_by( field, string, &block )
    Scaffold.find_by( 'books', field, string, Fields, &block )
  end

  def Book.method_missing( symbol, *args )
    if symbol.to_s =~ /^find_by_(\w+)$/i
      field = $1.to_sym
      raise "Invalid field #{field}" unless Fields.include?( field )
      Book.find_by( field, args ) { |row| yield row }
    else
      super
    end
  end

  def Book.create( args={}.freeze )
    book = Book.new( args )

    # Create a string of table fields, separated by commas, based
    # on the @fields variable set in #new
    field_list = Fields.map( &:to_s ).join( ', ' )

    Connector::connect do |c|
      # Insert into the table fields listed in field_list
      # the values in value_list
      c.query( "INSERT INTO books (#{field_list}) VALUES (
                  '#{book.isbn}', #{book.price}, #{book.quantity},
                  '#{book.title}', '#{book.author}', '#{book.publisher}'
                );")
    end

    book
  end

  def initialize( args={}.freeze )
    defaults = {
      :isbn => :MANDATORY,
      :price => 0,
      :quantity => 0,
      :title => :MANDATORY,
      :author => :MANDATORY,
      :publisher => :MANDATORY
    }
    
    args.each do |key, value|
      raise "Argument '#{key}' contains SQL" if key.to_s.contains_sql?
      raise "Value '#{value}' for argument '#{key}' contains SQL" if value.to_s.contains_sql?
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
  def Book.generate_isbn
    isbn = ''

    # Older ISBN's have 10 digits, new ISBN's have 13 digits
    digits = 10

    # Randomly determine if we're going to generate a 10-digit
    # or a 13-digit ISBN
    digits = 13 if rand < 0.5

    digits.times { isbn << rand( 9 ).to_s }

    isbn
  end

  # Nouns and adjectives taken from http://mdbenoit.com/rtg.htm
  def Book.generate_title
    nouns = ["Dream","Dreamer","Dreams","Waves", "Sword","Kiss",
      "Sex","Lover", "Slave","Slaves","Pleasure","Servant", "Servants",
      "Snake","Soul","Touch", "Men","Women","Gift","Scent", "Ice",
      "Snow","Night","Silk","Secret","Secrets", "Game","Fire","Flame",
      "Flames", "Husband","Wife","Man","Woman","Boy","Girl", "Truth",
      "Edge","Boyfriend","Girlfriend", "Body","Captive","Male","Wave",
      "Predator", "Female","Healer","Trainer","Teacher", "Hunter",
      "Obsession","Hustler","Consort", "Dream", "Dreamer", "Dreams",
      "Rainbow", "Dreaming","Flight","Flying","Soaring", "Wings","Mist",
      "Sky","Wind", "Winter","Misty","River","Door", "Gate","Cloud",
      "Fairy","Dragon", "End","Blade","Beginning","Tale", "Tales",
      "Emperor","Prince","Princess", "Willow","Birch","Petals","Destiny",
      "Theft","Thief","Legend","Prophecy", "Spark","Sparks","Stream",
      "Streams","Waves", "Sword","Darkness","Swords","Silence","Kiss",
      "Butterfly","Shadow","Ring","Rings","Emerald", "Storm","Storms",
      "Mists","World","Worlds", "Alien","Lord","Lords","Ship","Ships",
      "Star", "Stars","Force","Visions","Vision","Magic", "Wizards",
      "Wizard","Heart","Heat","Twins", "Twilight","Moon","Moons","Planet",
      "Shores", "Pirates","Courage","Time","Academy", "School","Rose",
      "Roses","Stone","Stones", "Sorcerer","Shard","Shards","Slave",
      "Slaves", "Servant","Servants","Serpent","Serpents", "Snake",
      "Soul","Souls","Savior","Spirit", "Spirits","Voyage","Voyages",
      "Voyager","Voyagers", "Return","Legacy","Birth","Healer","Healing",
      "Year","Years","Death","Dying","Luck","Elves", "Tears","Touch",
      "Son","Sons","Child","Children", "Illusion","Sliver","Destruction",
      "Crying","Weeping", "Gift","Word","Words","Thought","Thoughts",
      "Scent", "Ice","Snow","Night","Silk","Guardian","Angel", "Angels",
      "Secret","Secrets","Search","Eye","Eyes", "Danger","Game","Fire",
      "Flame","Flames","Bride", "Husband","Wife","Time","Flower",
      "Flowers", "Light","Lights","Door","Doors","Window","Windows",
      "Bridge","Bridges","Ashes","Memory","Thorn", "Thorns","Name",
      "Names","Future","Past", "History","Something","Nothing","Someone",
      "Nobody","Person","Man","Woman","Boy","Girl", "Way","Mage","Witch",
      "Witches","Lover", "Tower","Valley","Abyss","Hunter", "Truth","Edge"
    ]

    adjectives = ["Lost","Only","Last","First", "Third","Sacred",
      "Bold","Lovely", "Final","Missing","Shadowy","Seventh",
      "Dwindling","Missing","Absent", "Vacant","Cold","Hot","Burning",
      "Forgotten", "Weeping","Dying","Lonely","Silent", "Laughing",
      "Whispering","Forgotten","Smooth", "Silken","Rough","Frozen",
      "Wild", "Trembling","Fallen","Ragged","Broken", "Cracked",
      "Splintered","Slithering","Silky", "Wet","Magnificent",
      "Luscious","Swollen", "Erect","Bare","Naked","Stripped",
      "Captured","Stolen","Sucking","Licking", "Growing","Kissing",
      "Green","Red","Blue", "Azure","Rising","Falling","Elemental",
      "Bound","Prized","Obsessed","Unwilling", "Hard","Eager",
      "Ravaged","Sleeping", "Wanton","Professional","Willing",
      "Devoted", "Misty","Lost","Only","Last","First", "Final",
      "Missing","Shadowy","Seventh", "Dark","Darkest","Silver",
      "Silvery","Living", "Black","White","Hidden","Entwined",
      "Invisible", "Next","Seventh","Red","Green","Blue", "Purple",
      "Grey","Bloody","Emerald","Diamond", "Frozen","Sharp",
      "Delicious","Dangerous", "Deep","Twinkling","Dwindling",
      "Missing","Absent", "Vacant","Cold","Hot","Burning","Forgotten",
      "Some","No","All","Every","Each","Which","What", "Playful",
      "Silent","Weeping","Dying","Lonely","Silent", "Laughing",
      "Whispering","Forgotten","Smooth","Silken", "Rough","Frozen",
      "Wild","Trembling","Fallen", "Ragged","Broken","Cracked",
      "Splintered"
    ]

    nouns.delete_if { |noun| noun.contains_sql? }
    adjectives.delete_if { |adj| adj.contains_sql? }
    num_nouns = nouns.size - 1
    num_adjectives = adjectives.size - 1
    random_number = rand

    if random_number < 0.2
      adjective = adjectives[rand( num_adjectives )]
      noun = nouns[rand( num_nouns )]
      "#{adjective} #{noun}"
    elsif random_number > 0.2 && random_number < 0.4
      noun1 = nouns[rand( num_nouns )]
      noun2 = nouns[rand( num_nouns )]
      "#{noun1} of #{noun2}"
    elsif random_number > 0.4 && random_number < 0.6
      adjective1 = adjectives[rand( num_adjectives )]
      adjective2 = adjectives[rand( num_adjectives )]
      noun = nouns[rand( num_nouns )]
      "The #{adjective1} #{adjective2} #{noun}"
    elsif random_number > 0.6 && random_number < 0.8
      noun1 = nouns[rand( num_nouns )]
      noun2 = nouns[rand( num_nouns )]
      "The #{noun1} of the #{noun2}"
    else
      adjective = adjectives[rand( num_adjectives )]
      noun = nouns[rand( num_nouns )]
      "A #{adjective} #{noun}"
    end
  end

  # Put some initial rows in the books table
  def Book.populate
    first_names = ['Jim', 'Jane', 'Sarah', 'Tom', 'Mike', 'Alice', 'Kevin', 'Eric', 'Bob']
    last_names = ['Doe', 'Miller', 'James', 'Keith', 'Bradshaw', 'Bradley', 'Knight', 'Smith']
    publishers = ['Penguin Putnam', 'OReilly Media', 'Harper Collins', 'Ace Books', 'Algonquin Press', 'Agate', 'Atria', 'Arcade Publishing', 'Ballantine', 'Bantam']

    num_first_names = first_names.size - 1
    num_last_names = last_names.size - 1
    num_publishers = publishers.size - 1

    50.times do
      title = Book.generate_title
      first_name = first_names[rand( num_first_names )]
      last_name = last_names[rand( num_last_names )]
      author = "#{first_name} #{last_name}"
      publisher = publishers[rand( num_publishers )]
      isbn = Book.generate_isbn
      price = Scaffold.generate_price( 30 )
      quantity = rand( 100 )
      quantity += 1 if quantity == 0
      Book.create( :author => author, :publisher => publisher, :title => title, :isbn => isbn, :price => price, :quantity => quantity )
    end
  end
  
  def Book.delete( isbn )
    raise "ISBN '#{isbn}' contains SQL" if isbn.contains_sql?
    Connector::connect do |conn|
      conn.query( "DELETE FROM books WHERE isbn = '#{isbn}';" )
    end
  end
  
  def Book.search_form
    searchable_fields = ['isbn', 'title', 'author', 'publisher']
    str = ''

    str << <<END
<form action="#{BaseURI}/search.cgi" method="post">
<input type="hidden" name="product_type" value="book" />
  <fieldset>
    <legend>Search Books</legend>
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
  
  # drop books table, create it again, and populate it with random books
  def Book.reset
    Book.drop

    Connector::connect do |c|
      c.query( "CREATE TABLE books(
            isbn         VARCHAR(#{ISBNLength})      NOT NULL,
            price        FLOAT                       NOT NULL,
            quantity     INT                         NOT NULL,
            title        VARCHAR(#{MaxStringLength}) NOT NULL,
            author       VARCHAR(#{MaxStringLength}) NOT NULL,
            publisher    VARCHAR(#{MaxStringLength}) NOT NULL,
            PRIMARY KEY (isbn)
           );" )
    end

    Book.populate
  end

  def Book.exists?( isbn )
    Scaffold.exists?( 'books', 'isbn', isbn )
  end

  def Book.update( isbn, args={}.freeze )
    raise "Invalid ISBN given: '#{isbn}'" if isbn.nil? || isbn.to_s.blank?
    Scaffold.update( 'books', "isbn='#{isbn}'", args )
  end
end
