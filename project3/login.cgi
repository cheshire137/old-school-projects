#!/usr/bin/env ruby
require 'session.rb'
include Session

name = $cgi.params['name'].first
password = $cgi.params['password'].first
error = false

if name.nil? || name.blank?
  message = 'No login name given'
  error = true
end

unless Person.exists?( name )
  message = "The user &ldquo;#{name}&rdquo; does not exist"
  error = true
end

if password.nil? || password.blank?
  message = 'No password given'
  error = true
end

if error
  redirect( 'index.rhtml', true, message )
else
  if Person.password_valid?( name, password )
    $session[:user] = Person.find( name )
    message = "Successfully logged in as #{name}"
    redirect( 'index.rhtml', false, message )
  else
    $session[:user] = nil
    redirect( 'index.rhtml', true, 'Invalid login' )
  end
end
