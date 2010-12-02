# Provides logic for processing user input from the web form.  Interacts with
# the Client and UserLevel models to create, populate, and drop tables in the
# database as necessary.
class FormController < ApplicationController
  # This handles back-end processing for data given in a web form.  Will
  # redirect the user to the index page if it is accessed via any request type
  # other than POST.  If the user has correctly filled out the form, this will
  # create the vertically partitioned tables and populate them.
  def create_table
    unless request.post? # Only allow POST request
      redirect_to :action => :index, :error => "Please submit form"
      return
    end
    
    # Ensure all the required parameters were given in the form.
    check_params({:schema => "Missing table schema"})
    
    # Drop and recreate the tables, filling it with data.
    unless session[:cd].nil?
      session[:cd].drop_tables
    end
    cd = ColumnarDistribution.new(session[:schema])
    cd.create_tables
    cd.load_data
    
    # Store the new ColumnarDistribution instance in the session so we can use
    # it to run the user's SELECT queries later.
    session[:cd] = cd
    
    # Update a flag since at this point we have successfully created tables.
    session[:tables_created] = true
    
    # Redirect the user back to the form, which will show different fields
    # based on updated session data, and allow them to query the database.
    redirect_to :action => :index,
      :notice => "Successfully created table and loaded data"
  rescue => error # Catch any exceptions
    redirect_to :action => :index, :error => error
  end
  
  # Initializes values in the session if they aren't already set.
  def index
    # Initialize session values
    session[:schema] ||= ''
    session[:generated_query] ||= nil
    session[:query] ||= ''
    session[:columns] ||= nil
    session[:result] ||= nil
    session[:cd] ||= nil
    session[:tables_created] ||= false
    
    # If we've created the tables, then we can get descriptions of them for
    # display purposes.  Store these in instance variables so they're accessible
    # in the view.
    if session[:tables_created]
      @tables_desc = session[:cd].get_tables_descriptions()
      @tables_data = session[:cd].get_tables_rows_columns()
    end
  rescue => error # Catch any exceptions
    render :text => error
  end
  
  # When the user visits this page, their session data will be cleared, the
  # tables will be dropped, and then they will be redirected to the index page.
  def logout
    session[:cd].drop_tables if session[:cd]
    
    # Wipe the session
    session[:generated_query] = nil
    session[:schema] = nil
    session[:query] = nil
    session[:tables_created] = false
    session[:cd] = nil
    session[:columns] = nil
    session[:result] = nil
    reset_session
    
    # Redirect back to the index page
    redirect_to :action => :index,
      :notice => "Wiped session data, dropped table"
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
    
    # Reset session values in case something goes awry.
    session[:result] = nil
    session[:generated_query] = nil
    
    # Ensure we have an instance of the ColumnarDistribution class so we can run
    # the user's query.
    if session[:cd].nil?
      redirect_to :action => :index,
        :error => "No data for your table is loaded, cannot run query"
      return
    end
    
    # Check the given parameters from the form to ensure we got all the data
    # we need.
    check_params({:query => "Missing query"})
    
    # Try to generate a query based on the user's query, run that query, and
    # get the results.  Store the rows and columns of the query result in the
    # session so they can be displayed in an HTML table later.
    session[:generated_query], session[:result], session[:columns] =
      session[:cd].run_query(session[:query])
    
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
end
