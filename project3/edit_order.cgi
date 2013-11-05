#!/usr/bin/env ruby
require 'session.rb'
include Session

if $session[:user]
  product_type = $cgi.params['product_type'].first
  product_id = $cgi.params['product_id'].first
  order_id = $cgi.params['order_id'].first
  login_name = $cgi.params['login_name'].first
  new_quantity = $cgi.params['new_quantity'].first
  error = false

  if new_quantity.nil? || new_quantity.blank?
    redirect( 'person/account.rhtml', true, "Invalid quantity '#{new_quantity}' given" )
    error = true
  else
    new_quantity = new_quantity.to_i
  end

  if order_id.nil? || !Order.exists?( order_id )
    redirect( 'person/account.rhtml', true, "Invalid order ID '#{order_id}' given" )
    error = true
  end

  unless ['book', 'toy'].include?( product_type )
    redirect( 'person/account.rhtml', true, "Invalid product type &ldquo;#{product_type}&rdquo; given" )
    error = true
  end

  if product_id.nil? || product_id.blank?
    redirect( 'person/account.rhtml', true, 'No product in the order was specified to change' )
    error = true
  end

  unless login_name == $session[:user].login_name
    redirect( 'person/account.rhtml', true, 'Given user was not yourself&mdash;you cannot edit orders for other users' )
    error = true
  end

  unless error
    product = product_type.tablify.find( product_id )

    if product.nil?
      raise "Invalid product: #{product.inspect}; tried to find #{product_type} with primary key value #{product_id}"
    end

    if new_quantity == 0
      OrderItem.delete( order_id, product_id, product_type )
      message = 'Removed '

      if product_type == 'book'
        message << " book '#{product.title}' by #{product.author} "
      else
        message << " toy '#{product.name}' "
      end

      message << 'from your cart'

      # If the item we just deleted was the last one in the order,
      # go ahead and delete the order
      unless Order.has_items?( order_id )
        Order.delete( order_id )
      end
    else
      OrderItem.update(
        order_id,
        product_id,
        product_type,
        :quantity => new_quantity
      )

      message = 'Updated quantity of '

      if product_type == 'book'
        message << " book '#{product.title}' by #{product.author} "
      else
        message << " toy '#{product.name}' "
      end

      message << "to #{new_quantity}"
    end

    redirect( 'person/cart.rhtml', false, message )
  end
else
  redirect( 'index.rhtml', true, 'You must log in to edit an order' )
end
