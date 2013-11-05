#!/usr/bin/env ruby

# erb.cgi
#
# Apache script handler for .rhtml files
# based on work by Brian Bugh and Paul McArdle
# see http://dekstop.de/weblog/2006/01/rhtml_on_osx_with_apache_and_erb/
#
# Martin Dittus (martin@dekstop.de), 2006-01-09

require 'erb'
require 'session.rb'
include Session

# If a page is in one of these arrays, that means you have to have
# at least that status to access the page.  E.g. index.rhtml
# is in CustomerPages, so you must be at least a customer to access
# index.rhtml.
# Manager > Staff > Customer
CustomerPages = ['account.rhtml', 'cart.rhtml', 'order_info.rhtml'].freeze
StaffPages = ['admin.rhtml', 'edit.rhtml', 'delete.rhtml', 'new.rhtml', 'sales_by_toy.rhtml', 'sales_by_customer.rhtml', 'sales_by_book.rhtml'].freeze
ManagerPages = ['source_viewer.rhtml'].freeze
RestrictedPages = [CustomerPages, StaffPages, ManagerPages].flatten.freeze

def get_curr_page
  File.basename( ENV['PATH_TRANSLATED'] )
end

def get_parent_dir( basename=nil )
  basename = get_curr_page if basename.nil?
  path = ENV['PATH_TRANSLATED'].gsub( /\/#{basename}$/, '' )
  position = path.reverse.index( /\// )
  path[-position..path.length]
end

# Used to get the value of a form field, if it has been saved in the
# session
def get_value( field )
  if $session[:form] && $session[:form].has_key?( field )
    $session[:form][field]
  else
    ''
  end
end

curr_page = get_curr_page

# Catch visitors that aren't logged in at all but are trying to access
# a restricted page
if (
  RestrictedPages.include?( curr_page ) &&
  $session[:user] == nil &&
  # Allow non-logged-in users to register a new account
  (get_parent_dir + '/' + curr_page) != 'person/new.rhtml'
)
  redirect( 'index.rhtml', true, 'You must log in to access that page' )
else
  if $session[:user]
    # I.e. :customer, :staff, or :manager
    user_status = $session[:user].person_type.to_sym
  else
    user_status = nil
  end

  # Catch users that are only customers but are trying to access
  # either manager or staff-only pages
  if (
    ( StaffPages.include?( curr_page ) ||
      ManagerPages.include?( curr_page ) ) &&
    user_status == :customer
  )
    redirect( 'index.rhtml', true, 'That area is restricted to staff only' )
  # Catch users that are only customers or staff but are trying to
  # access manager-only pages
  elsif ManagerPages.include?( curr_page ) && [:customer, :staff].include?( user_status )
    redirect( 'index.rhtml', true, 'That area is restricted to managers only' )
  # Otherwise, the user is trying to access a page to which they
  # have access, so let them through
  else
    path = nil

    if ( ENV['PATH_TRANSLATED'] )
      path = ENV['PATH_TRANSLATED']
    else
      if ENV['REDIRECT_URL'].include?( File.basename( __FILE__ ) )
        file_path = ENV['SCRIPT_URL']
      else
        file_path = ENV['REDIRECT_URL']
      end

      path = File.expand_path( ENV['DOCUMENT_ROOT'] + '/' + file_path )
      raise "Attempt to access invalid path: #{path}" unless path.index( ENV['DOCUMENT_ROOT'] ) == 0
    end

    erb = File.open( path ) { |f| ERB.new( f.read ) }
    header_file = BaseDir + '/header.rhtml'
    header = File.open( header_file ) { |f| ERB.new( f.read ) }
    footer_file = BaseDir + '/footer.rhtml'
    footer = File.open( footer_file ) { |f| ERB.new( f.read ) }
    debug_file = BaseDir + '/debug.rhtml'
    debug = File.open( debug_file ) { |f| ERB.new( f.read ) }

    begin
      print $cgi.header
      print header.result( binding )
      print erb.result( binding )
      print debug.result( binding )
      print footer.result( binding )

      # Reset the message stored in the session so that it doesn't
      # keep printing out on every page
      $session[:message] = ''
    rescue Exception
      # error message
      print "<h2>Script Error</h2>\n"
      print "<pre>#{$!}</pre>\n"

      print debug.result( binding )

      # debug info
      print "<h2>Backtrace</h2>\n"
      print "<pre>#{$!.backtrace.debug}</pre>\n"

      print "<h2>Environment</h2>\n"
      env_list = ENV.keys.collect { |key| key + ' = ' + ENV[key] + "\n"}
      print "<pre>#{env_list}</pre>\n"
    end
  end
end
