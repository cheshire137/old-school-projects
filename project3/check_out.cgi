#!/usr/bin/env ruby
require 'session.rb'
include Session

# Things we need to do at check out:
# 1) Mark the order as 'completed';
# 2) Decrement the quantity in the books and/or toys table by the
#    quantity purchased by the user

if $session[:user]
  order_id = $cgi.params['order_id'].first
  login_name = $cgi.params['login_name'].first
  error = false

  # Store the user's input in the session so that we can fill out the
  # form again for them if they messed something up and have to redo it
  $session[:form] = {}
  $cgi.params.each do |field, value|
    $session[:form][field.to_sym] = value
  end

  unless Order.exists?( order_id )
    redirect( 'person/cart.rhtml', true, "Invalid order ID #{order_id} given" )
    error = true
  end

  unless login_name == $session[:user].login_name
    redirect( 'index.rhtml', true, 'You can only check out as yourself, not as another user' )
    error = true
  end

  CreditCard::Fields.each do |field|
    value = $cgi.params[field.to_s].first

    if value.nil? || value.blank?
      redirect( 'person/cart.rhtml', true, "Missing credit card information: #{field}" )
      error = true
      break
    end
  end

  company = $cgi.params['company'].first

  unless CreditCard::Companies.include?( company )
    list = CreditCard::Companies.to_sentence

    redirect( 'person/cart.rhtml', true, "Invalid company '#{company}' given; accepted credit card companies include: #{list}" )
    error = true
  end

  unless error
    # Go through all the items in this order, and for each one,
    # decrement the quantity of that item in its respective table
    # by the amount the user is purchasing in this order
    OrderItem.find_all_by_order( order_id ) do |row|
      product_table = row.product_type.tablify # Book or Toy
      product = product_table.find( row.product_id )
      new_quantity = product.quantity - row.quantity

      if row.product_type == 'book'
        primary_key = product.isbn
      else
        primary_key = product.upc
      end

      # e.g. Book.update( '5815181455083', :quantity => 3 )
      product_table.update( primary_key, :quantity => new_quantity )
    end

    $session[:form] = nil
    Order.update( order_id, :status => 'completed' )
    redirect( 'index.rhtml', false, "Successfully submitted order ##{order_id}" )
  end
else
  redirect( 'index.rhtml', true, 'You cannot check out unless you are logged in' )
end
