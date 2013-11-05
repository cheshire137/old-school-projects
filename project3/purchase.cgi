#!/usr/bin/env ruby
require 'session.rb'
include Session

if $session[:user]
  product_type = $cgi.params['product_type'].first
  product_id = $cgi.params['product_id'].first
  login_name = $cgi.params['login_name'].first
  redirect_to = $cgi.params['return'].first
  error = false

  redirect_to = 'index.rhtml' if redirect_to.nil? || redirect_to.blank?

  unless ['book', 'toy'].include?( product_type )
    redirect( redirect_to, true, "Invalid product type &ldquo;#{product_type}&rdquo; given" )
    error = true
  end

  if product_id.nil? || product_id.blank?
    redirect( redirect_to, true, 'No product was specified to purchase' )
    error = true
  end

  unless login_name == $session[:user].login_name
    redirect( redirect_to, true, 'Given user was not yourself&mdash;you cannot make purchases for other users' )
    error = true
  end

  unless error
    order = Order.get_in_progress( login_name ) || Order.create( :login_name => login_name )
    product = product_type.tablify.find( product_id )

    if product.nil?
      raise "Invalid product: #{product.inspect}; tried to find #{product_type} with primary key value #{product_id}"
    end

    item = OrderItem.create(
      :order_id => order.id,
      :product_id => product_id,
      :product_type => product_type,
      :price => product.price,
      :quantity => 1
    )

    if product_type == 'book'
      name = product.title
    else
      name = product.name
    end

    redirect( redirect_to, false, "Successfully added 1 of &ldquo;#{name}&rdquo; to your <a href=\"#{BaseURI}/person/cart.rhtml\">cart</a>" )
  end
else
  redirect( 'index.rhtml', true, 'You must log in to purchase an item' )
end
