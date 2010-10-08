# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_proj1_rails_session',
  :secret      => '77ff5a23eeba8d03434bc49a6a1fdd1f358952d6661de80bec962d3f3f6d49c66d6c9317440f51c9d62896efc393d68440242ab6bf0353c289a90d5389173e76'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
