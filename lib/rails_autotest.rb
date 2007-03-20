require 'autotest'

class RailsAutotest < Autotest

  def initialize # :nodoc:
    super
    @exceptions = /^\.\/(?:db|doc|log|public|script|vendor\/rails)/

    @test_mappings = {
      %r%^test/fixtures/(.*)s.yml% => proc { |_, m|
        ["test/unit/#{m[1]}_test.rb",
         "test/controllers/#{m[1]}_controller_test.rb",
         "test/views/#{m[1]}_view_test.rb",
         "test/functional/#{m[1]}_controller_test.rb"]
      },
      %r%^test/(unit|integration|controllers|views|functional)/.*rb$% => proc { |filename, _|
        filename
      },
      %r%^app/models/(.*)\.rb$% => proc { |_, m|
        ["test/unit/#{m[1]}_test.rb"]
      },
      %r%^app/helpers/application_helper.rb% => proc {
        files_matching %r%^test/(views|functional)/.*_test\.rb$%
      },
      %r%^app/helpers/(.*)_helper.rb% => proc { |_, m|
        if m[1] == "application" then
          files_matching %r%^test/(views|functional)/.*_test\.rb$%
        else
          ["test/views/#{m[1]}_view_test.rb",
           "test/functional/#{m[1]}_controller_test.rb"]
        end
      },
      %r%^app/views/(.*)/% => proc { |_, m|
        ["test/views/#{m[1]}_view_test.rb",
         "test/functional/#{m[1]}_controller_test.rb"]
      },
      %r%^app/controllers/(.*)\.rb$% => proc { |_, m|
        if m[1] == "application" then
          files_matching %r%^test/(controllers|views|functional)/.*_test\.rb$%
        else
          ["test/controllers/#{m[1]}_test.rb",
           "test/functional/#{m[1]}_test.rb"]
        end
      },
      %r%^app/views/layouts/% => proc {
        "test/views/layouts_view_test.rb"
      },
      %r%^config/routes.rb$% => proc { # FIX:
        files_matching %r%^test/(controllers|views|functional)/.*_test\.rb$%
      },
      %r%^test/test_helper.rb|config/((boot|environment(s/test)?).rb|database.yml)% => proc {
        files_matching %r%^test/(unit|controllers|views|functional)/.*_test\.rb$%
      },
    }
  end

  def tests_for_file(filename)
    super.select { |f| @files.has_key? f }
  end

  def path_to_classname(s)
    sep = File::SEPARATOR
    f = s.sub(/^test#{sep}((unit|functional|integration|views|controllers|helpers)#{sep})?/, '').sub(/\.rb$/, '').split(sep)
    f = f.map { |path| path.split(/_/).map { |seg| seg.capitalize }.join }
    f = f.map { |path| path =~ /Test$/ ? path : "#{path}Test"  }
    f.join('::')
  end
end
