# Represents a column in a table.  Provides methods to determine the type of the
# column as well as ensure good data.
class Column
  NameRegex = /^[a-zA-Z]+[a-zA-Z0-9]+$/
  RangeRegex = /(\(\d+\)$)|(\(\d,\d\)$)/
  RestrictedRegex = /class$/
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
    
    # Ensure the type is either numeric or a varchar, the only two allowed
    # user-given types
    unless type.starts_with?('numeric') || type.starts_with?('varchar')
      raise "Invalid field type #{type}, expected only numeric or varchar"
    end
    
    # Store the given data in member variables
    @name = name
    @type = type
    @function = nil
  end
  
  # Returns the name of the associated classification column for this column,
  # based on this column's name.  If this column is itself a classification
  # column, nil is returned.
  def get_class_column
    if restricted?
      return nil
    end
    @name.first + 'class'
  end
  
  # Returns true if this is a classification column.
  def restricted?
    !(@name =~ RestrictedRegex).nil?
  end
  
  # Returns true if this column is a numeric type.
  def numeric?
    !(@type =~ NumericRegex).nil?
  end
  
  # Returns true if this column is a varchar type.
  def varchar?
    !(@type =~ VarcharRegex).nil?
  end
end
