#!/usr/local/bin/ruby -ws

# ut_filter - a ruby unit test filter by Ryan Davis <ryand-ruby@zenspider.com>
#
# usage:
#
#  test.rb | ut_filter.rb [options]
#    options:
#    -l prefix line numbers on the diffs
#    -u unified diff
#    -c contextual diff
#    -v display version

require 'tempfile'

UTF_VERSION = '1.0.0'

data = []
current = []
data << current

if defined? $v then
  puts "#{File.basename $0} v. #{UTF_VERSION}"
  exit
end

$l = false unless defined? $l
$u = false unless defined? $u
$c = false unless defined? $c

diff_flag = $u ? "-u" : $c ? "-c" : ""

def temp_file(data)
  temp = Tempfile.new("diff")
  count = 0
  data = data.map { |l| '%3d) %s' % [count+=1, l] } if $l
  temp.puts data.join('')
  temp.flush
  temp
end

# Collect
ARGF.each_line do |line|
  if line =~ /^\s*\d+\) (Failure|Error):/
    type = $1
    current = []
    data << current
  end
  current << line
end

# Output
data.each do |result|
  first = []
  second = []
  found = false

  if result.first !~ /Failure/ then
    puts result.join('')
    next
  end

  result.each do |line|
    if found then
      second << line
    else
      found = true if line.sub!(/ expected but was/, '')
      first << line
    end
  end

  header = first.shift + first.shift # count, type + test_name, line
  footer = second.pop # blank or summary
  second.pop # blank line
  second.last.sub!(/\.$/, '') unless second.empty?

  puts header
  puts `diff #{diff_flag} #{temp_file(first).path} #{temp_file(second).path}`
  puts footer
end
