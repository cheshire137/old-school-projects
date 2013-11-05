require 'yaml'

class Object
  # Akin to Ruby on Rails's debug method, found in
  # actionpack-1.13.2/lib/action_view/helpers/debug_helper.rb
  def debug
    begin
      Marshal::dump( self )
      "<pre class='debug_dump'>#{self.to_yaml.gsub( "  ", "&nbsp; " )}</pre>"
    rescue Exception => e  # errors from Marshal or YAML
      # Object couldn't be dumped, perhaps because of singleton methods -- this is the fallback
      "<code class='debug_dump'>#{self.inspect}</code>"
    end
  end
end
