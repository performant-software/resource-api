class String
  def is_integer?
    true if Integer(self) rescue false
  end

  def to_bool
    return true if self == true || self =~ /^(true|t|yes|y|1)$/i
    false
  end
end
