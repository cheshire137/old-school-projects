#!/usr/bin/env ruby
require 'session.rb'
include Session

if $session[:user]
  args = {}
  error = false

  Person::Fields.each do |field|
    # Don't allow a user to change their person type; only the
    # normal-user 'Update my Info' form will pass information
    # to this CGI script, so only customers will be changing
    # their shipping info, stuff like that
    next if [:person_type, :password].include?( field )

    unless $cgi.params[field.to_s].first
      redirect( 'person/account.rhtml', true, "You must give a value for #{field}" )
      error = true
      break
    end

    args[field] = $cgi.params[field.to_s].first
  end

  if args[:login_name] != $session[:user].login_name
    redirect( 'index.rhtml', true, 'You can only update your own information, not that of other users' )
    error = true
  end

  unless error
    Person.update( $session[:user].login_name, args )
    $session[:user] = Person.find( $session[:user].login_name )
    redirect( 'person/account.rhtml', false, 'Successfully updated your information' )
  end
else
  redirect( 'index.rhtml', true, 'You must log in to update your user info' )
end
