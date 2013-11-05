require 'book/book.rb'

Book.find_all.each do |row|
  Book::Fields.each do |field|
    puts field.to_s + "\t" + row.send( field ).to_s + "\n"
  end
end
