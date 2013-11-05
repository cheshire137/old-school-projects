# See http://api.rubyonrails.com/classes/ActiveSupport/CoreExtensions/Array/Conversions.html
class Array
  def to_sentence
    case length
      when 0
        ''
      when 1
        self[0]
      when 2
        "#{self[0]} and #{self[1]}"
      else
        "#{self[0...-1].join(', ')}, and #{self[-1]}"
    end
  end
end
