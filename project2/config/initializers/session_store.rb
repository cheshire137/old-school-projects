# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_project2_session',
  :secret      => 'bda3bcb38a54d503ec4a96e473a8465676973c906d37945c90ba32a4b7dd02bc213b331dc43a32256c8097973016cfd121b8c31e3e292aa85a45c83824a390bb'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
