class FormController < ApplicationController
  RequiredFields = {:schema => "Missing table schema",
    :user_levels => "Missing user levels table schema",
    :user_name => "Missing user name",
    :query => "Missing query"}
  
  def index
    RequiredFields.each do |field, errMsg|
      session[field] ||= ''
    end
    session[:columns] ||= nil
    session[:result] ||= nil
    @schema = session[:schema]
    @user_levels = session[:user_levels]
    @user_name = session[:user_name]
    @query = session[:query]
    @result = session[:result]
    @columns = session[:columns]
  end
  
  def run_query
    unless request.post? # Only allow POST method
      redirect_to :action => :index, :error => "Please submit form"
      return
    end
    all_given = true
    error_messages = []
    RequiredFields.each do |field, error_message|
      if params.has_key?(field) && !params[field].blank?
        session[field] = params[field]
      else
        all_given = false
        error_messages << error_message
      end
    end
    unless all_given
      redirect_to :action => :index, :error => error_messages.join(", ")
      return
    end
    ul = UserLevel.new(session[:user_levels])
    ul.drop_table
    ul.create_table
    ul.load_data
    client = Client.new(session[:schema])
    client.drop_table
    client.create_table
    client.load_data
    mysql_result = client.run_query(session[:user_name], session[:query])
    session_storable_result = []
    while row = mysql_result.fetch_hash do
      session_storable_result << row
    end
    session[:result] = session_storable_result
    session[:columns] = mysql_result.fetch_fields.map(&:name)
    redirect_to :action => :index,
      :notice => sprintf(
        "Successfully constructed database and ran query, getting %d rows",
        session[:result].length
      )
  rescue => error # Catch any exceptions
    redirect_to :action => :index, :error => error
  end
end
