require_relative 'argument_contains_sql.rb'

# See Ruby Cookbook, pp. 296
module KeywordProcessor
  MANDATORY = :MANDATORY

  # Takes the arguments from the user and the default arguments;
  # checks out the user's arguments and makes sure such keywords
  # exist and that no mandatory values were left out
  def process_args( raw_args, defaults )
    args = {}
    raw_args.each do |k, v|
      raise ArgumentContainsSQL, "Keyword '#{k}' contains SQL" if k.to_s.contains_sql?
      raise ArgumentContainsSQL, "Value '#{v}' for keyword #{k} contains SQL" if v.to_s.contains_sql?
      args[k.to_sym] = v
    end

    args.keys.each do |key|
      unless defaults.has_key?( key.to_sym )
        raise ArgumentError, "No such keyword argument: #{key}"
      end
    end
    result = defaults.dup.update( args )

    unfilled = result.select do |k, v|
      v == MANDATORY || v.to_s.empty?
    end.map { |k,v| k.inspect }

    unless unfilled.empty?
      msg = "Mandatory keyword parameter(s) not given: #{unfilled.to_sentence}"
      raise ArgumentError, msg
    end

    result
  end
end
