class Column
  NameRegex = /^[a-zA-Z]+[a-zA-Z0-9]+$/
  RangeRegex = /(\(\d+\)$)|(\(\d,\d\)$)/
  RestrictedRegex = /class$/
  NumericRegex = /^numeric/
  VarcharRegex = /^varchar/
  attr_reader :name, :type
  
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
    if (name =~ NameRegex).nil?
      raise "Invalid column name--must be alphanumeric, cannot begin with number"
    end
    if (type =~ RangeRegex).nil?
      raise "Invalid field type--no range specified on #{type}"
    end
    unless type.starts_with?('numeric') || type.starts_with?('varchar')
      raise "Invalid field type #{type}, expected only numeric or varchar"
    end
    @name = name
    @type = type
  end
  
  def get_class_column
    if restricted?
      return nil
    end
    @name.first + 'class'
  end
  
  def restricted?
    !(@name =~ RestrictedRegex).nil?
  end
  
  def numeric?
    !(@type =~ NumericRegex).nil?
  end
  
  def varchar?
    !(@type =~ VarcharRegex).nil?
  end
end
