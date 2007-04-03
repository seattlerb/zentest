module Autotest::Emacs
  def self.emacs_autotest status
    `emacsclient -e \"(autotest-update '#{status})\"`
  end

  Autotest.add_hook :run_command do  |at|
    emacs_autotest :running
  end

  Autotest.add_hook :green do  |at|
    emacs_autotest :passed
  end

  Autotest.add_hook :all_good do  |at|
    emacs_autotest :passed
  end

  Autotest.add_hook :red do  |at|
    emacs_autotest :failed
  end

  Autotest.add_hook :quit do  |at|
    emacs_autotest :quit
  end
end
