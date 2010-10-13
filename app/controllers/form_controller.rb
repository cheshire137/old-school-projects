class FormController < ApplicationController
  def create_tables
    unless request.post? # Only allow POST method
      redirect_to :action => :index, :error => "Please submit form"
      return
    end
    session[:client] = nil
    check_params({:schema => "Missing clients table schema",
      :user_levels => "Missing user levels schema"})
    ul = UserLevel.new(session[:user_levels])
    ul.drop_table
    ul.create_table
    ul.load_data
    client = Client.new(session[:schema])
    client.drop_table
    client.create_table
    client.load_data
    session[:client] = client
    session[:tables_created] = true
    redirect_to :action => :index,
      :notice => "Successfully created tables and loaded data"
  rescue => error # Catch any exceptions
    redirect_to :action => :index, :error => error
  end
  
  def index
    session[:user_name] ||= ''
    session[:schema] ||= ''
    session[:user_levels] ||= ''
    session[:query] ||= ''
    session[:columns] ||= nil
    session[:result] ||= nil
    session[:client] ||= nil
    session[:tables_created] ||= false
  end
  
  def logout
    Client.drop_table
    UserLevel.drop_table
    RequiredFields.each do |field, errMsg|
      session[field] = nil
    end
    session[:query] = nil
    session[:tables_created] = false
    session[:client] = nil
    session[:columns] = nil
    session[:result] = nil
    reset_session
    redirect_to :action => :index,
      :notice => "Wiped session data, dropped tables"
  end
  
  def run_query
    unless request.post? # Only allow POST method
      redirect_to :action => :index, :error => "Please submit form"
      return
    end
    if params.has_key? :logout
      redirect_to :action => :logout
      return
    end
    if session[:client].nil?
      redirect_to :action => :index,
        :error => "No data for clients table is loaded, cannot run query"
      return
    end
    check_params({:query => "Missing query",
      :user_name => "Missing user name"})
    session[:result] = nil
    mysql_result = session[:client].run_query(session[:user_name],
      session[:query])
    session_storable_result = []
    while row = mysql_result.fetch_hash do
      session_storable_result << row
    end
    session[:result] = session_storable_result
    session[:columns] = mysql_result.fetch_fields.map(&:name)
    redirect_to :action => :index,
      :notice => sprintf(
        "Successfully ran query, getting %d rows",
        session[:result].length
      )
  rescue => error # Catch any exceptions
    redirect_to :action => :index, :error => error
  end
  
  private
    def check_params(required_params)
      all_given = true
      error_messages = []
      required_params.each do |key, error_message|
        if params.has_key?(key) && !params[key].blank?
          session[key] = params[key]
        else
          all_given = false
          error_messages << error_message
        end
      end
      raise error_messages.join(', ') unless all_given
    end
end
