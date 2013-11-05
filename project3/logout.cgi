#!/usr/bin/env ruby
require 'session.rb'
include Session
$session[:user] = nil
$session.delete
$session.close
redirect( 'index.rhtml', false, 'Successfully logged out' )
