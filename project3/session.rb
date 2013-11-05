#!/usr/bin/env ruby
require 'cgi'
require 'cgi/session'
require 'cgi/session/pstore'
require 'config.rb'

['book', 'order', 'person', 'toy', 'credit_card', 'order_item'].each do |table|
  require BaseDir + "/#{table}/#{table}.rb"
end

module Session
  $cgi = CGI.new
  $session = CGI::Session.new(
    $cgi,
    'database_manager' => CGI::Session::PStore
  )

  def redirect( to, error=false, message='' )
    str = "Location: #{BaseURI}/#{to}"
    $session[:message] = message
    str += "?error=true" if error
    str += EOL + EOL
    print str
  end
end
