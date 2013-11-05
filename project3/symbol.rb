class Symbol
  # See http://pragdave.pragprog.com/pragdave/2005/11/symbolto_proc.html
  def to_proc
    proc { |obj, *args| obj.send(self, *args) }
  end
end
