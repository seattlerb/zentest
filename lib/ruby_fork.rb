require 'optparse'
require 'socket'

module RubyFork

  PORT = 9084

  DEFAULT_SETTINGS = {
    :requires => [],
    :code => [],
    :extra_paths => [],
    :port => PORT,
  }

  def self.add_env_args(opts, settings)
    opts.separator ''
    opts.separator 'Process environment options:'

    opts.separator ''
    opts.on('-e CODE', 'Execute CODE in parent process.',
            'May be specified multiple times.') do |code|
      settings[:code] << code
    end

    opts.separator ''
    opts.on('-I DIRECTORY', 'Adds DIRECTORY to $LOAD_PATH.',
            'May be specified multiple times.') do |dir|
      settings[:extra_paths] << dir
    end

    opts.separator ''
    opts.on('-r LIBRARY', 'Require LIBRARY in the parent process.',
            'May be specified multiple times.') do |lib|
      settings[:requires] << lib
    end
  end

  def self.daemonize(io = File.open('/dev/null', 'r+'))
    exit!(0) if fork
    Process::setsid
    exit!(0) if fork

    STDIN.reopen io
    STDOUT.reopen io
    STDERR.reopen io

    yield if block_given?
  end

  def self.parse_client_args(args)
    settings = Marshal.load Marshal.dump(DEFAULT_SETTINGS)

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.separator ''
      opts.on('-p', '--port PORT',
              'Listen for connections on PORT.',
              "Default: #{settings[:port]}") do |port|
        settings[:port] = port.to_i
              end

      opts.separator ''
      opts.on('-h', '--help', 'You\'re looking at it.') do
        $stderr.puts opts
        exit 1
      end

      add_env_args opts, settings
    end

    opts.parse! args

    return settings
  end

  def self.parse_server_args(args)
    settings = Marshal.load Marshal.dump(DEFAULT_SETTINGS)
    settings[:daemonize] = false

    opts = OptionParser.new do |opts|
      opts.banner = "Usage: #{$0} [options]"

      opts.separator ''
      opts.on('-d', '--daemonize',
              'Run as a daemon.',
              "Default: #{settings[:daemonize]}") do |val|
        settings[:daemonize] = val
      end

      opts.separator ''
      opts.on('-p', '--port PORT',
              'Listen for connections on PORT.',
              "Default: #{settings[:port]}") do |port|
        settings[:port] = port.to_i
      end

      opts.separator ''
      opts.on('-h', '--help', 'You\'re looking at it.') do
        $stderr.puts opts
        exit 1
      end

      add_env_args opts, settings
    end

    opts.parse! args

    return settings
  end

  def self.start_client(args = ARGV)
    settings = parse_client_args args

    args = Marshal.dump [settings, ARGV]

    socket = TCPSocket.new 'localhost', settings[:port]

    socket.puts args.length
    socket.write args
    socket.close_write

    until socket.eof?
      STDOUT.puts socket.gets
    end
  end

  def self.start_server(args = ARGV)
    settings = RubyFork.parse_server_args args
    RubyFork.setup_environment settings

    RubyFork.daemonize if settings[:daemonize]

    server = TCPServer.new 'localhost', settings[:port]

    $stderr.puts "#{$0} Running as PID #{$$} on #{settings[:port]}" unless
      settings[:daemonize]

    loop do
      begin
        socket = server.accept

        args_length = socket.gets.to_i
        args = socket.read args_length
        settings, argv = Marshal.load args

        fork do
          daemonize socket do
            ARGV.replace argv
            setup_environment settings
            socket.close
          end
        end

        socket.close # close my copy.
      rescue => e
        socket.close if socket
      end
    end
  end

  def self.setup_environment(settings)
    settings[:extra_paths].map! { |dir| dir.split ':' }
    settings[:extra_paths].flatten!
    settings[:extra_paths].each { |dir| $:.unshift dir }

    settings[:requires].each { |file| require file }

    settings[:code].each { |code| eval code }
  end

end

