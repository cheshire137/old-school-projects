#!/usr/bin/env ruby
require 'session.rb'
include Session

query = $cgi.params['query'].first
product_type = $cgi.params['product_type'].first
field = $cgi.params['field'].first
table = product_type.tablify
error = false
valid_fields = ['manufacturer', 'name', 'isbn', 'title', 'author', 'publisher']

if query.nil? || query == ''
  message = 'No search query was entered'
  error = true
end

if product_type.nil? || product_type == ''
  message = 'No product type (book or toy) was given'
  error = true
end

if field.nil? || field == ''
  message = 'No search field was selected'
  error = true
end

unless valid_fields.include?( field )
  message = "Invalid search field selected--valid fields include: #{valid_fields.to_sentence}"
  error = true
end

redirect( 'logged_in.rhtml', true, message ) if error

$session[:search] = {
  :method => "find_by_#{field}".to_sym,
  :query => query,
  :table => table
}

redirect( 'search_results.rhtml' )
