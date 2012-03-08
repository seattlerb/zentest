# -*- ruby -*-

module Autotest::Timestamp
  Autotest.add_hook :ran_command do
    puts
    puts "# Finished at #{Time.now.strftime "%Y-%m-%d %H:%M:%S"}"
    puts
  end
end
