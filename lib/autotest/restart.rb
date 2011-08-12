module Autotest::Restart
  Autotest.add_hook :initialize do |at|
    configs = [File.expand_path('~/.autotest'), './.autotest']
    at.extra_files.concat configs
    false
  end

  Autotest.add_hook :updated do |at, updated|
    unless updated.keys.grep(/\.autotest$/).empty? then
      warn "Detected change to .autotest, restarting"
      at.restart
    end
  end
end
