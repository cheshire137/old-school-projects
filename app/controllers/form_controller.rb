# Provides logic for processing user input from the web form.  Interacts with
# the Client and UserLevel models to create, populate, and drop tables in the
# database as necessary.
class FormController < ApplicationController
  # This handles back-end processing for data given in a web form.  Will
  # redirect the user to the index page if it is accessed via any request type
  # other than POST.  If the user has correctly filled out the form, this will
  # create tables user_levels and clients, as well as populate them with data.
  def create_tables
    unless request.post? # Only allow POST request
      redirect_to :action => :index, :error => "Please submit form"
      return
    end
    
    # Reset the Client instance in the session, in case something goes awry
    # before we redirect the user back to run a query using the Client model.
    session[:client] = nil
    
    # Ensure all the required parameters were given in the form.
    check_params({:schema => "Missing clients table schema",
      :user_levels => "Missing user levels schema"})
    
    # Drop and recreate the user_levels table, filling it with data.
    UserLevel.drop_table
    ul = UserLevel.new(session[:user_levels])
    ul.create_table
    ul.load_data
    
    # Drop and recreate the clients table, filling it with data.
    Client.drop_table
    client = Client.new(session[:schema])
    client.create_table
    client.load_data
    
    # Store the new Client instance in the session so we can use it to run
    # the user's SELECT queries later.
    session[:client] = client
    
    # Update a flag since at this point we have successfully created both
    # tables.
    session[:tables_created] = true
    
    # Redirect the user back to the form, which will show different fields
    # based on updated session data, and allow them to query the database.
    redirect_to :action => :index,
      :notice => "Successfully created tables and loaded data"
  rescue => error # Catch any exceptions
    redirect_to :action => :index, :error => error
  end
  
  # Initializes values in the session if they aren't already set.
  def index
    # Initialize session values
    session[:user_name] ||= ''
    session[:schema] ||= ''
    session[:user_levels] ||= ''
    session[:generated_query] ||= nil
    session[:query] ||= ''
    session[:columns] ||= nil
    session[:result] ||= nil
    session[:client] ||= nil
    session[:tables_created] ||= false
    
    # If we've created the tables, then we can get descriptions of them for
    # display purposes.  Store these in instance variables so they're accessible
    # in the view.
    if session[:tables_created]
      @clients_desc_rows, @clients_desc_cols =
        get_rows_and_columns(Client.describe)
      @user_levels_desc_rows, @user_levels_desc_cols =
        get_rows_and_columns(UserLevel.describe)
    end
  rescue => error # Catch any exceptions
    render :text => error
  end
  
  # When the user visits this page, their session data will be cleared, the
  # tables will be dropped, and then they will be redirected to the index page.
  def logout
    # Drop tables
    Client.drop_table
    UserLevel.drop_table
    
    # Wipe the session
    session[:user_name] = nil
    session[:generated_query] = nil
    session[:schema] = nil
    session[:user_levels] = nil
    session[:query] = nil
    session[:tables_created] = false
    session[:client] = nil
    session[:columns] = nil
    session[:result] = nil
    reset_session
    
    # Redirect back to the index page
    redirect_to :action => :index,
      :notice => "Wiped session data, dropped tables"
  rescue => error # Catch any exceptions
    redirect_to :action => :index, :error => error
  end
  
  # The user will be sent to this page when they submit their SELECT query in
  # the form.  This will redirect if any request method other than POST is used.
  # The user also ends up here if they hit the button to wipe their session.
  # Depending on which button was pushed in the form, the user will either be
  # logged off or their query will be parsed and executed.  Results of the query
  # will be stored in the session and the user will be redirected to the index
  # page.
  def run_query
    unless request.post? # Only allow POST request
      redirect_to :action => :index, :error => "Please submit form"
      return
    end
    
    # Check if the user was trying to wipe their session/drop tables.  If so,
    # redirect them and return.
    if params.has_key? :logout
      redirect_to :action => :logout
      return
    end
    
    # Ensure we have an instance of the Client class so we can run the user's
    # query.
    if session[:client].nil?
      redirect_to :action => :index,
        :error => "No data for clients table is loaded, cannot run query"
      return
    end
    
    # Check the given parameters from the form to ensure we got all the data
    # we need.
    check_params({:query => "Missing query",
      :user_name => "Missing user name"})
    
    # Reset the result of the query in the session in case something goes awry.
    session[:result] = nil
    
    # Try to generate a query based on the user's query, run that query, and
    # get the results.
    session[:generated_query], mysql_result =
      session[:client].run_query(session[:user_name], session[:query])
      
    # Store the rows and columns of the query result in the session so they
    # can be displayed in an HTML table later.
    session[:result], session[:columns] = get_rows_and_columns(mysql_result)
    
    # Redirect the user back to the index page, which will show the query
    # results.
    redirect_to :action => :index,
      :notice => sprintf(
        "Successfully ran query, getting %d rows",
        session[:result].length
      )
  rescue => error # Catch any exceptions
    redirect_to :action => :index, :error => error
  end
  
  # All methods below will be private to this class.
  private
    # Takes a hash describing required fields the user should have passed in
    # the form, as well as error messages describing those fields if the user
    # did not provide all of them.  Will initialize the associated session
    # fields to store the field values from the form.  Throws an exception if
    # there are any missing fields.
    def check_params(required_params)
      all_given = true
      error_messages = []
      
      # Iterate over all the required parameters and their error messages
      required_params.each do |key, error_message|
        # Ensure the required parameter was given and does not have a blank
        # value
        if params.has_key?(key) && !params[key].blank?
          # Store the form value in the session
          session[key] = params[key]
        else
          # Whoops, user didn't give us a value for this required field
          all_given = false
          error_messages << error_message
        end
      end
      # Throw an exception unless all required fields were given
      raise error_messages.join(', ') unless all_given
    end
    
    # Given a MySQL result, this will extract column names and return both the
    # column names and hashes of the values in each row of the results.
    def get_rows_and_columns(mysql_result)
      rows = []
      while row = mysql_result.fetch_hash do
        rows << row
      end
      columns = mysql_result.fetch_fields.map(&:name)
      
      # Return the row hashes and the column names
      [rows, columns]
    end
end
