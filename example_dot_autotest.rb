# -*- ruby -*-

module AutoGrowl
  def self.growl title, msg, pri=0
    system "growlnotify -n autotest --image /Applications/Mail.app/Contents/Resources/Caution.tiff -p #{pri} -m #{msg.inspect} #{title}"
  end

  Autotest.add_hook :run do  |at|
    growl "Run", "Run" unless $TESTING
  end

  Autotest.add_hook :red do |at|
    growl "Tests Failed", "#{at.files_to_test.size} tests failed", 2
  end

  Autotest.add_hook :green do |at|
    growl "Tests Passed", "All tests passed", -2 if at.tainted 
  end

  Autotest.add_hook :init do |at|
    growl "autotest", "autotest was started" unless $TESTING
  end

  Autotest.add_hook :interrupt do |at|
    growl "autotest", "autotest was reset" unless $TESTING
  end

  Autotest.add_hook :quit do |at|
    growl "autotest", "autotest is exiting" unless $TESTING
  end

  Autotest.add_hook :all do |at|_hook
    growl "autotest", "Tests have fully passed", -2 unless $TESTING
  end
end

module HtmlConsole
  MAX = 30
  STATUS = {}
  PATH = File.expand_path("~/Sites/autotest.html")

  def self.update
    STATUS.delete STATUS.keys.sort.last if STATUS.size > MAX
    File.open(PATH, "w") do |f|
      f.puts "<title>Autotest Status</title>"
      STATUS.sort.reverse.each do |t,s|
        if s > 0 then
          f.puts "<p style=\"color:red\">#{t}: #{s}"
        else
          f.puts "<p style=\"color:green\">#{t}: #{s}"
        end
      end
    end
  end

  Autotest.add_hook :red do |at|
    STATUS[Time.now] = at.files_to_test.size
    update
  end

  Autotest.add_hook :green do |at|
    STATUS[Time.now] = 0
    update
  end
end

require 'osx/cocoa'
include Math
include OSX

OSX::NSBundle.bundleWithPath(File.expand_path("~/Library/Frameworks/Aquaterm.framework")).load
OSX.ns_import :AQTAdapter

class StatusBoard
  BLACK = 0
  WHITE = 1
  RED = 2
  GREEN = 3
  GRAY = 4

  def initialize
    @past = []

    @adapter = AQTAdapter.alloc.init
    @adapter.openPlotWithIndex 1
    @adapter.setPlotSize([122,122])
    @adapter.setPlotTitle("Autotest Status")

    @adapter.setColormapEntry_red_green_blue(0, 0.0, 0.0, 0.0) # black
    @adapter.setColormapEntry_red_green_blue(1, 1.0, 1.0, 1.0) # white
    @adapter.setColormapEntry_red_green_blue(2, 1.0, 0.0, 0.0) # red
    @adapter.setColormapEntry_red_green_blue(3, 0.0, 1.0, 0.0) # green
    @adapter.setColormapEntry_red_green_blue(4, 0.7, 0.7, 0.7) # gray

    draw
  end

  def draw
#    @past = @past[10..-1] if @past.size >= 100
    @past.shift if @past.size > 100

    @adapter.takeColorFromColormapEntry(@past.last ? GREEN : RED)
    @adapter.addFilledRect([0, 0, 122, 122])

    @adapter.takeColorFromColormapEntry(BLACK)
    @adapter.addFilledRect([10, 10, 102, 102])

    @adapter.takeColorFromColormapEntry(GRAY)
    @adapter.addFilledRect([11, 11, 100, 100])

    @adapter.takeColorFromColormapEntry(0)

    @past.each_with_index do |passed,i|
      x = i % 10
      y = i / 10
      
      @adapter.takeColorFromColormapEntry(passed ? GREEN : RED)
      @adapter.addFilledRect([x*10+11, y*10+11, 10, 10])
    end
    @adapter.renderPlot
  end

  def pass
    @past.push true
    draw
  end

  def fail
    @past.push false
    draw
  end

  def close
    @adapter.closePlot
  end
end

unless $TESTING then
  board = StatusBoard.new

  Autotest.add_hook :red do |at|
    board.fail unless $TESTING
  end

  Autotest.add_hook :green do |at|
    board.pass unless $TESTING
  end
end
