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

require 'tempfile'

UTF_VERSION = '1.1.0'

data = []
current = []
data << current

if defined? $v then
  puts "#{File.basename $0} v. #{UTF_VERSION}"
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

$b = false unless defined? $b
$c = false unless defined? $c
$k = false unless defined? $k
$l = false unless defined? $l
$u = false unless defined? $u

diff_flags = $u ? "-u" : $c ? "-c" : ""
diff_flags += " -b" if $b


class Tempfile
  # blatently stolen. Design was poor in Tempfile.
  def self.make_tempname(basename, n=10)
    sprintf('%s%d.%d', basename, $$, n)
  end

  def self.make_temppath(basename)
    tempname = ""
    n = 1
    begin
      tmpname = File.join('/tmp', make_tempname(basename, n))
      n += 1
    end while File.exist?(tmpname) and n < 100
    tmpname
  end
end

def temp_file(data)
  temp = if $k then
           File.new(Tempfile.make_temppath("diff"), "w")
         else
           Tempfile.new("diff")
         end
  count = 0
  data = data.map { |l| '%3d) %s' % [count+=1, l] } if $l
  data = data.join('')
  # unescape newlines, strip <> from entire string
  data = data.gsub(/\\n/, "\n").gsub(/\A</, '').gsub(/>\Z/, '')
  temp.puts data
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

  if found then
    header = first.shift + first.shift # count, type + test_name, line
    footer = second.pop # blank or summary
    second.pop if second.last =~ /^\s*$/ # blank line
    second.last.sub!(/\.$/, '') unless second.empty?
    
    puts header
    puts `diff #{diff_flags} #{temp_file(first).path} #{temp_file(second).path}`
    puts footer
  else
    puts first.join('')
  end
end
