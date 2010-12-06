# Represents a column in a table.  Provides methods to determine the type of the
# column as well as ensure good data.
class Column
  IntRegex = /^int/
  NameRegex = /^[a-zA-Z]+[a-zA-Z0-9]+$/
  RangeRegex = /(\(\d+\)$)|(\(\d,\d\)$)/
  NumericRegex = /^numeric/
  VarcharRegex = /^varchar/
  
  # Make the @name and @type members readable outside of this class.
  attr_reader :name, :type
  
  # Make the @function member readable and writeable outside of this class.
  attr_accessor :function
  
  # Constructor taking a column name and a type.  Throws an exception if bad
  # data is given.
  def initialize(name, type)
    if name.nil? || name.blank?
      raise "Invalid column name, cannot be blank or nil"
    end
    if type.nil? || type.blank?
      raise "Invalid column type, cannot be blank or nil"
    end
    
    name.strip! # Trim whitespace
    name.downcase! # Lowercase
    type.strip!
    type.downcase!
    
    # Ensure the column name is valid
    if (name =~ NameRegex).nil?
      raise "Invalid column name--must be alphanumeric, cannot begin with number"
    end
    
    # Ensure the type has a range specified on it, e.g., (2,5) for a numeric
    # type or (12) for a varchar or numeric
    if (type =~ RangeRegex).nil?
      raise "Invalid field type--no range specified on #{type}"
    end
    
    # Ensure the type is numeric, int, or a varchar
    if (@type =~ NumericRegex).nil? && (@type =~ IntRegex).nil? && (@type =~ VarcharRegex).nil?
      raise "Invalid field type #{type}, expected only numeric, int, or varchar"
    end
    
    # Store the given data in member variables
    @name = name
    @type = type
    @function = nil
  end
  
  def ==(other)
    return false unless other.respond_to?(:name)
    return false unless other.respond_to?(:type)
    return false unless other.respond_to?(:function)
    @name == other.name && @type == other.type && @function == other.function
  end
  
  # Returns true if this column is a numeric type.
  def numeric?
    !(@type =~ NumericRegex).nil? || !(@type =~ IntRegex).nil?
  end
  
  # Returns true if this column is a varchar type.
  def varchar?
    !(@type =~ VarcharRegex).nil?
  end
end
