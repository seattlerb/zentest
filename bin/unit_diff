#!/usr/local/bin/ruby -ws
# 
# unit_diff - a ruby unit test filter by Ryan Davis <ryand-ruby@zenspider.com>
#
# usage:
#
#  test.rb | unit_diff [options]
#    options:
#    -b ignore whitespace differences
#    -c contextual diff
#    -h show usage
#    -k keep temp diff files around
#    -l prefix line numbers on the diffs
#    -u unified diff
#    -v display version

require 'ZenTest'

############################################################

if __FILE__ == $0 then

  UNIT_DIFF_VERSION = '1.1.0'

  if defined? $v then
    puts "#{File.basename $0} v. #{UNIT_DIFF_VERSION}"
    exit
  end

  if defined? $h then
    File.open(File.basename($0)) do |f|
      begin; end until f.readline =~ /usage:/
      f.readline
      while line = f.readline and line.sub!(/^# ?/, '')
        $stderr.puts line
      end
    end
    exit 0
  end

  puts UnitDiff.unit_diff(ARGF)
end
