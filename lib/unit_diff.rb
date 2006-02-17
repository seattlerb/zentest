class UnitDiff

  def self.unit_diff(input)
    ud = UnitDiff.new
    ud.unit_diff(input)
  end

  def input(input)
    current = []
    data = []
    data << current

    # Collect
    input.each_line do |line|
      if line =~ /^\s*$/ or line =~ /^\(?\s*\d+\) (Failure|Error):/ then
        type = $1
        current = []
        data << current
      end
      current << line
    end
    data = data.reject { |o| o == ["\n"] }
    header = data.shift
    footer = data.pop
    return header, data, footer
  end

  def parse_diff(result)
    header = []
    expect = []
    butwas = []
    found = false
    state = :header

    until result.empty? do
      case state
      when :header then
        header << result.shift 
        state = :expect if result.first =~ /^</
      when :expect then
        state = :butwas if result.first.sub!(/ expected but was/, '')
        expect << result.shift
      when :butwas then
        butwas = result[0..-1]
        result.clear
      else
        raise "unknown state #{state}"
      end
    end

    return header, expect, nil if butwas.empty?

    expect.last.chomp!
    expect.first.sub!(/^<\"/, '')
    expect.last.sub!(/\">$/, '')

    butwas.last.chomp!
    butwas.last.chop! if butwas.last =~ /\.$/
    butwas.first.sub!( /^<\"/, '')
    butwas.last.sub!(/\">$/, '')

    return header, expect, butwas
  end

  def unit_diff(input)

    $b = false unless defined? $b
    $c = false unless defined? $c
    $k = false unless defined? $k
    $l = false unless defined? $l
    $u = false unless defined? $u

    output = []

    header, data, footer = self.input(input)

    # Output
    data.each do |result|
      first = []
      second = []

      if result.first !~ /Failure/ then
        output.push result.join('')
        next
      end

      prefix, expect, butwas = parse_diff(result)

      output.push prefix.compact.map {|line| line.strip}.join("\n")

      if butwas then
        a = temp_file(expect)
        b = temp_file(butwas)

        diff_flags = $u ? "-u" : $c ? "-c" : ""
        diff_flags += " -b" if $b

        result = `diff #{diff_flags} #{a.path} #{b.path}`
        if result.empty? then
          output.push "[no difference--suspect ==]"
        else
          output.push result.map {|line| line.strip}
        end

        output.push ''
      else
        output.push expect.join('')
      end
    end

    footer.shift if footer.first.strip.empty?
    output.push footer.compact.map {|line| line.strip}.join("\n")

    return output.flatten.join("\n")
  end

end

