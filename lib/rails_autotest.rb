require 'autotest'

class RailsAutotest < Autotest

  def initialize # :nodoc:
    super
    @exceptions = %r%^\./(?:db|doc|log|public|script|vendor/rails)%
  end

  def tests_for_file(filename)

    case filename
    when %r%^test/fixtures/(.*)s.yml% then
      ["test/unit/#{$1}_test.rb",
       "test/controllers/#{$1}_controller_test.rb",
       "test/views/#{$1}_view_test.rb",
       "test/functional/#{$1}_controller_test.rb"]
    when %r%^test/(unit|integration|controllers|views|functional)/.*rb$% then
      [filename]
    when %r%^app/models/(.*)\.rb$% then
      ["test/unit/#{$1}_test.rb"]
    when %r%^app/helpers/application_helper.rb% then
      @files.keys.select { |f|
        f =~ %r%^test/(views|functional)/.*_test\.rb$%
      }
    when %r%^app/helpers/(.*)_helper.rb%, %r%^app/views/(.*)/% then
      ["test/views/#{$1}_view_test.rb",
       "test/functional/#{$1}_controller_test.rb"]
    when %r%^app/controllers/application.rb$% then # FIX: wtf?
      ["test/controllers/dummy_controller_test.rb",
       "test/functional/dummy_controller_test.rb"]
    when %r%^app/controllers/(.*)\.rb$% then
      ["test/controllers/#{$1}_test.rb",
       "test/functional/#{$1}_test.rb"]
    when %r%^app/views/layouts/% then
      ["test/views/layouts_view_test.rb"]
    when %r%^config/routes.rb$% then
      @files.keys.select do |f|
        f =~ %r%^test/(controllers|views|functional)/.*_test\.rb$%
      end
    when %r%^test/test_helper.rb%,
         %r%^config/((boot|environment(s/test)?).rb|database.yml)% then
      @files.keys.select do |f|
        f =~ %r%^test/(unit|controllers|views|functional)/.*_test\.rb$%
      end
    else
      @output.puts "Dunno! #{filename}" if $TESTING
      []
    end.uniq.select { |f| @files.has_key? f }
  end

  def path_to_classname(s)
    sep = File::SEPARATOR
    f = s.sub(/^test#{sep}((unit|functional|integration|views|controllers|helpers)#{sep})?/, '').sub(/\.rb$/, '').split(sep)
    f = f.map { |path| path.split(/_/).map { |seg| seg.capitalize }.join }
    f = f.map { |path| path =~ /Test$/ ? path : "#{path}Test"  }
    f.join('::')
  end
end

