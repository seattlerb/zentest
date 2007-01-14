# -*- ruby -*-

module Autotest::Timestamp
  Autotest.add_hook :waiting do |at|
    puts
    puts "# Waiting at #{Time.now.strftime "%Y-%m-%d %H:%M:%S"}"
    puts
  end
end
