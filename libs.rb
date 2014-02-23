# http://stackoverflow.com/questions/8382619/how-to-round-a-float-to-a-specified-number-of-significant-digits-in-ruby
class Float
  def signif(signs)
    Float("%.#{signs}g" % self)
  end
end

