# -*- ruby -*-

class Autotest

  def growl title, msg, pri=0
    system "growlnotify -n autotest --image /Applications/Mail.app/Contents/Resources/Caution.tiff -p #{pri} -m #{msg.inspect} #{title}"
  end

  def red_hook
    growl "Tests Failed", "#{@files_to_test.size} tests failed", 2
  end
  
  def green_hook
    growl "Tests Passed", "All tests passed", -2 if @tainted 
  end

  def init_hook
    growl "autotest", "autotest was started" unless $TESTING
  end

  def interrupt_hook
    growl "autotest", "autotest was reset" unless $TESTING
  end

  def quit_hook
    growl "autotest", "autotest is exiting" unless $TESTING
  end

  def all_good_hook
    growl "autotest", "Tests have fully passed", -2 unless $TESTING
  end
end
