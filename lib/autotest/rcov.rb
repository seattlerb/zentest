module Autotest::RCov
  @@pattern = "test/*.rb"

  def self.pattern= o
    @@pattern = o
  end

  Autotest.add_hook :all_good do |at|
    system "rake rcov_info PATTERN=test/test_ruby_lexer.rb"
  end
end

