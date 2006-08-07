# -*- ruby -*-

# special thanks to Pat Eyler, Sean Carley, and Rob Sanheim
module RedGreen
  BAR = "=" * 80

  Autotest.add_hook :ran_command do |at|
    at.results.gsub!(/^.* (\d+) failures, (\d+) errors$/) { |match|
      code = ($1 != "0" or $2 != "0") ? 31 : 32
      "\e[#{code}m#{BAR}\n#{match}\e[0m\n\n"
    }
  end
end
