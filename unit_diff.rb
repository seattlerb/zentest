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
  temp = 
    if $k then
      File.new(Tempfile.make_temppath("diff"), "w")
    else
      Tempfile.new("diff")
    end
  count = 0
  data = data.map { |l| '%3d) %s' % [count+=1, l] } if $l
  data = data.join('')
  # unescape newlines, strip <> from entire string
  data = data.gsub(/\\n/, "\n").gsub(/\A</m, '').gsub(/>\Z/m, '').gsub(/0x[a-f0-9]+/m, '0xXXXXXX')
  temp.puts data
  temp.flush
  temp.rewind
  temp
end

# Collect
ARGF.each_line do |line|
  if line =~ /^\(?\s*\d+\) (Failure|Error):/ then
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
    header = []
    header << first.shift while first.first !~ /^</

    footer = []
    footer.unshift second.pop while second.last !~ /tests.*assertions.*failures/ and not second.last.nil?
    footer.unshift second.pop

    second.pop while second.last =~ /^\s*$/ # blank line
    second.last.sub!(/\.$/, '') unless second.empty?
    
    puts header

    a = temp_file(first)
    b = temp_file(second)

    result = `diff #{diff_flags} #{a.path} #{b.path}`
    if result.empty? then
      puts "[no difference--suspect ==]"
    else
      puts result
    end
    puts
    puts footer
  else
    puts first.join('')
  end
end
