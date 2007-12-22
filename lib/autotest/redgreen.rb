# -*- ruby -*-

# special thanks to Pat Eyler, Sean Carley, and Rob Sanheim
module Autotest::RedGreen
  BAR = "=" * 80

  Autotest.add_hook :ran_command do |at|
    if at.results.last =~ /^.* (\d+) failures, (\d+) errors$/
      code = ($1 != "0" or $2 != "0") ? 31 : 32
      puts "\e[#{code}m#{BAR}\e[0m\n\n"
    end
  end
end
