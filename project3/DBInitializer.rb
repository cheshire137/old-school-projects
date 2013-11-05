#!/usr/bin/env ruby
# This is a big reset button for the database.
# This script drops all tables in the database
# related to the project that are present and 
# recreates the tables, leaving them empty.
require 'Connector.rb'
include Connector
#puts "Connection established..."
#conn = DBConnection.connect
#DBConnection.speak
#puts "Reseting all tables..."
#conn.reset_all_tables
#puts "Listing tables..."
#conn.list_tables
#puts "Done!  Closing connection."
#conn.close

puts "Establishing connection..."
DBConnection.connect do |conn|
  conn.speak
  puts "Resetting all tables..."
  conn.reset_all_tables
  puts "Tables in the database:"
  conn.list_tables
  puts "Done!  Closing connection."
end