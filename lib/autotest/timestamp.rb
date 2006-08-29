# -*- ruby -*-

module Autotest::Timestamp
  Autotest.add_hook :waiting do |at|
    puts "# waiting... #{Time.now}"
  end
end
