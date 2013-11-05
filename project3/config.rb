#!/usr/bin/env ruby
BaseDir = '/home/moneypenny/cs405.3till7.net'.freeze
BaseURI = 'http://cs405.3till7.net'.freeze
EOL = "\r\n".freeze
DebugMode = true.freeze
ShippingHandling = 5.freeze
SalesTax = 0.06.freeze
require BaseDir + '/string.rb'
require BaseDir + '/keyword_processor.rb'
require BaseDir + '/symbol.rb'
require BaseDir + '/array.rb'
require BaseDir + '/object.rb'
require BaseDir + '/argument_contains_sql.rb'

def get_new_id
  require 'digest/md5'
  md5 = Digest::MD5::new
  now = Time.now
  md5.update( now.to_s )
  md5.update( String( now.usec ) )
  md5.update( String( rand( 0 ) ) )
  md5.update( String( $$ ) )
  md5.update( 'foobar' )
  md5.hexdigest
end
