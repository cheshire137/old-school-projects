#!/usr/bin/env ruby
require 'session.rb'
include Session

if $session[:user]
  old_password = $cgi.params['old_password'].first
  new_password = $cgi.params['new_password'].first
  new_password_again = $cgi.params['new_password_again'].first
  login_name = $cgi.params['login_name'].first

  if old_password.nil? || old_password.blank?
    redirect( 'person/account.rhtml', true, 'You must give your current password in order to change it' )
    error = true
  end

  if old_password == new_password
    redirect( 'person/account.rhtml', true, 'Your new password cannot match your old password' )
    error = true
  end

  if new_password.nil? || new_password.blank?
    redirect( 'person/account.rhtml', true, 'No new password given' )
    error = true
  end

  if new_password_again.nil? || new_password_again.blank?
    redirect( 'person/account.rhtml', true, 'You must retype your new password' )
    error = true
  end

  unless new_password == new_password_again
    redirect( 'person/account.rhtml', true, 'Your new passwords did not match--please retype them' )
    error = true
  end

  unless login_name == $session[:user].login_name
    redirect( 'index.rhtml', true, 'You can only change your own password' )
    error = true
  end

  unless error
    Person.change_password( login_name, old_password, new_password )
    redirect( 'person/account.rhtml', false, 'Successfully changed password' )
  end
else
  redirect( 'index.rhtml', true, 'You must be logged in to change your password' )
end
