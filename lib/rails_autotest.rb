require 'autotest'

class RailsAutotest < Autotest

  def initialize # :nodoc:
    super
    @exceptions = %r%(?:^\./(?:db|doc|log|public|script))|(?:.rhtml$)%
  end

  def map_file_names(updated) # :nodoc:
    model_tests = []
    functional_tests = []

    updated.each do |filename|
      filename.sub!(/^\.\//, '') # trim the ./ that Find gives us

      case filename
      when %r%^test/fixtures/(.*)s.yml% then
        model_test = "test/unit/#{$1}_test.rb"
        functional_test = "test/functional/#{$1}_controller_test.rb"
        model_tests << model_test if File.exists? model_test
        functional_tests << functional_test if File.exists? functional_test
      when %r%^test/unit/.*rb$% then
        model_tests << filename
      when %r%^app/models/(.*)\.rb$% then
        model_tests << "test/unit/#{$1}_test.rb"
      when %r%^test/functional/.*\.rb$% then
        functional_tests << filename
      when %r%^app/helpers/application_helper.rb% then
        functional_tests.push(*Dir['test/functional/*_test.rb'])
      when %r%^app/helpers/(.*)_helper.rb% then
        functional_tests << "test/functional/#{$1}_controller_test.rb"
      when %r%^app/controllers/application.rb$% then
        functional_tests << "test/functional/dummy_controller_test.rb"
      when %r%^app/controllers/(.*)\.rb$% then
        functional_tests << "test/functional/#{$1}_test.rb"
      when %r%^app/views/layouts/% then
      when %r%^app/views/(.*)/% then
        functional_tests << "test/functional/#{$1}_controller_test.rb"
      else
        puts "dunno! #{filename}"
      end
    end

    model_tests.uniq!
    functional_tests.uniq!

    return model_tests, functional_tests
  end

end

