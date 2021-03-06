class Params
  # use initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  def initialize(req, route_params = {})
    @params = {}
    @params.merge!(route_params)
    @params.merge!(parse_www_encoded_form(req.body))
    @params.merge!(parse_www_encoded_form(req.query_string))
  end

  def [](key)
    @params[key.to_s] || @params[key.to_sym]
  end

  # this will be useful if we want to `puts params` in the server log
  def to_s
    @params.to_s
  end

  class AttributeNotFoundError < ArgumentError; end;

  private
  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    return {} if www_encoded_form.nil?
    pairs = www_encoded_form.split("&")
    hash = Hash.new
    pairs.each do |pair|
      key = pair.match(/^(.*)=/)[1]
      value = pair.match(/\=(.*)/)[1]
      keys = parse_key(key)
      hash.deep_merge!(assign_keys(keys, value))
    end
    hash
  end

  def assign_keys(keys, value)
    hash = Hash.new
    if keys.length == 1
      hash[keys.first] = value
    else
      hash[keys.shift] = assign_keys(keys, value)
    end
    hash
  end

  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    keys = key.split /\[|\]\[|\]/
  end
end

class Hash
  def deep_merge!(hash)
    hash.each do |key, value|
      self[key].nil? ? self[key] = value : self[key].deep_merge!(value)
    end
    self
  end
end

#assign_keys/deep_merge! can be done iteratively once you have the keys and value
#but I like recursion
# so data = [[[key1, key2, key3], value], [[key1, key2, key4], value2]
# and params = {}
# data.each do |pair|
#   pair[0].each do |key|
#     if key = pair[0].last
#       params[key] = pair[1]
#     else
#       params[key] ||= {}
#       params = params[key]
#     end
#   end
# end
