class JSONable
  def to_json
    hash = {}
    self.instance_variables.each do |var|
      hash[var] = self.instance_variable_get var
    end
    hash.to_json
  end

  def from_json! string
    JSON.load(string).each do |var, val|
      self.instance_variable_set "@#{var}", val
    end
  end

  def to_hash
    hash = {}
    instance_variables.each {|var| hash[var.to_s.delete("@")] = instance_variable_get(var) }
    hash.delete '_id'
    hash
  end
end
