# http://stackoverflow.com/questions/8382619/how-to-round-a-float-to-a-specified-number-of-significant-digits-in-ruby
class Float
  def signif(signs)
    Float("%.#{signs}g" % self)
  end
end

# Cache JSON
def get_cached url
  resp = open(url).read
  JSON.parse resp
end
