#!/usr/bin/env ruby
require 'config.rb'
require 'session.rb'
include Session

method = $cgi.params['action'].first.to_sym
table_name = $cgi.params['table'].first
table = table_name.tablify || nil
fields = $cgi.keys - ['table', 'action']
error = false

# Store the user's input in the session so that we can fill out the
# form again for them if they messed something up and have to redo it
$session[:form] = {}
fields.each do |field|
  $session[:form][field.to_sym] = $cgi[field.to_s]
end

if table && method
  begin
    args = []

    if [:update, :delete].include?( method ) && !['staff', 'manager'].include?( $session[:user].person_type )
      error = true
      redirect( 'index.rhtml', true, 'You do not have the authority to edit or delete items' )
    end

    if table == Person && method == :create
      password = $cgi.params['password'].first
      password_again = $cgi.params['password_again'].first
      login_name = $cgi.params['login_name'].first

      if password_again.nil? || password_again.blank?
        error = true
        redirect( 'person/new.rhtml', true, 'You must re-enter your password to confirm it' )
      end

      if password.nil? || password.blank?
        error = true
        redirect( 'person/new.rhtml', true, 'You must enter a password' )
      end

      unless password == password_again
        error = true
        redirect( 'person/new.rhtml', true, 'Passwords did not match' )
      end

      if login_name.nil? || login_name.blank?
        error = true
        redirect( 'person/new.rhtml', true, 'You must provide a login name' )
      end

      if Person.exists?( login_name )
        error = true
        redirect( 'person/new.rhtml', true, 'That login name is taken; please choose another' )
      end

      fields -= ['password_again']
    elsif table == Toy && [:update, :delete].include?( method )
      upc = $cgi.params['upc'].first
      primary_key = upc

      unless Toy.exists?( upc )
        error = true
        redirect( 'toy/edit.rhtml', true, "Invalid UPC '#{upc}' given" )
      end
    elsif table == Book && [:update, :delete].include?( method )
      isbn = $cgi.params['isbn'].first
      primary_key = isbn

      unless Book.exists?( isbn )
        error = true
        redirect( 'book/edit.rhtml', true, "Invalid ISBN '#{isbn}' given" )
      end
    elsif table == Person && [:update, :delete].include?( method )
      login_name = $cgi.params['login_name'].first
      primary_key = login_name

      unless Person.exists?( login_name )
        error = true
        redirect( 'admin.rhtml', true, "Invalid login name '#{login_name}' given " )
      end
    end

    unless error
      fields.each do |field|
        value = $cgi[field]
        args << ":#{field} => '#{value}'"
      end

      arg_list = args.join( ', ' )

      if method == :update
        to_eval = "#{table}.#{method}( '#{primary_key}', #{arg_list} )"
      elsif method == :delete
        to_eval = "#{table}.#{method}( '#{primary_key}' )"
      else
        if args.empty?
          to_eval = "#{table}.#{method}"
        else
          to_eval = "#{table}.#{method}( #{arg_list} )"
        end
      end

      eval( to_eval )

      # Delete information from the form because they successfully
      # filled it out
      $session[:form] = nil

      if table == Person && method == :create
        redirect( 'index.rhtml', false, 'Successfully created new account' )
      else
        message = "Successfully #{method}d #{table_name}"
        
        if table == Person && [:update, :delete].include?( method )
          page = 'admin.rhtml'
        else
          page = "#{table_name}/list.rhtml"
        end

        redirect( page, false, message )
      end
    end
  rescue ArgumentError => error
    error = error.to_s.gsub( /^#{BaseDir}\/keyword_processor\.rb:\d\d?:in `process_args':\s/, '' )

    if table == Person
      redirect( 'person/new.rhtml', true, error )
    else
      redirect( "#{table_name}/list.rhtml", true, error )
    end
  rescue => error
    print $cgi.header
    print "<p><strong>Error:</strong> <code>#{error}</code></p>"
    print "<p><strong>Tried to evaluate:</strong> <code>#{to_eval}</code></p>"
  end
else
  print $cgi.header
  print "<p><strong>Error:</strong> invalid action or table given.</p>"
end
