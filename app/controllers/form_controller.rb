class FormController < ApplicationController
  @@req_fields = {:schema => "Missing table schema",
    :user_levels => "Missing user levels table schema",
    :user_name => "Missing user name",
    :query => "Missing query"}
  
  def index
    @@req_fields.each do |field, errMsg|
      session[field] ||= ''
    end
    @schema = session[:schema]
    @user_levels = session[:user_levels]
    @user_name = session[:user_name]
    @query = session[:query]
  end
  
  def run_query
    unless request.post?
      redirect_to :action => :index, :error => "Please submit form"
      return
    end
    all_given = true
    errorMessages = []
    @@req_fields.each do |field, errMsg|
      if params.has_key?(field) && !params[field].blank?
        session[field] = params[field]
      else
        all_given = false
        errorMessages << errMsg
      end
    end
    unless all_given
      redirect_to :action => :index, :error => errorMessages.join(", ")
      return
    end
    UserLevel.drop_table
    UserLevel.create_table(session[:user_levels])
    UserLevel.load_data(session[:user_levels])
  rescue => error
    redirect_to :action => :index, :error => error
  end
end
