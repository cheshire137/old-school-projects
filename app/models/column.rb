class Column
  RangeRegex = /(\(\d+\)$)|(\(\d,\d\)$)/
  attr_reader :name, :type
  
  def initialize(name, type)
    if name.nil? || name.blank?
      raise "Invalid column name, cannot be blank or nil"
    end
    if type.nil? || type.blank?
      raise "Invalid column type, cannot be blank or nil"
    end
    name.strip! # Trim whitespace
    type.strip!
    type.downcase! # Lowercase
    if (name =~ ModelBase::NameRegex).nil?
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
end
