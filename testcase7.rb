
# nested class
module MyModule # in 1.9+ you'll not need this
end

class MyModule::MyClass
  def []; end
  def missingtest1; end
end
