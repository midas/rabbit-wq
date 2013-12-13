 require 'rubygems'
require 'rabbit_wq'
require 'trollop'
require 'yell'

module RabbitWQ
  class Cli

    attr_reader :cmd,
                :options

    SUB_COMMANDS = %w(
      restart
      start
      status
      stop
    )

    DEFAULT_CONFIG_PATH = "/etc/#{APP_ID}/#{APP_ID}.conf"
    DEFAULT_LOG_PATH    = "/var/log/#{APP_ID}/#{APP_ID}.log"
    DEFAULT_PID_PATH    = "/var/run/#{APP_ID}/#{APP_ID}.pid"

    DEFAULT_NUMBER_OF_THREADS = 1

    def initialize( args )
      Trollop::options do
        version VERSION_COPYRIGHT
        banner <<-EOS
#{APP_NAME} #{VERSION_COPYRIGHT}

Usage:
  #{APP_ID} [command] [options]

  commands:
#{SUB_COMMANDS.map { |sub_cmd| "    #{sub_cmd}" }.join( "\n" )}

  (For help with a command: #{APP_ID} [command] -h)

options:
      EOS
        stop_on SUB_COMMANDS
      end

      # Get the sub-command and its options
      #
      @cmd = ARGV.shift || ''
      @options = case( cmd )
        when "restart"
          Trollop::options do
            opt :config, "The path for the config file", :type => String, :short => '-c', :default => DEFAULT_CONFIG_PATH
            opt :log_level, "The log level", :type => String, :default => 'info'
            opt :log, "The path for the log file", :type => String, :short => '-l', :default => DEFAULT_LOG_PATH
            opt :pid, "The path for the PID file", :type => String, :default => DEFAULT_PID_PATH
            opt :threads, "The number of threads", :type => Integer, :default => DEFAULT_NUMBER_OF_THREADS, :short => '-t'
          end
        when "start"
          Trollop::options do
            opt :config, "The path for the config file", :type => String, :short => '-c', :default => DEFAULT_CONFIG_PATH
            opt :interactive, "Execute the server in interactive mode", :short => '-i'
            opt :log_level, "The log level", :type => String, :default => 'info'
            opt :log, "The path for the log file", :type => String, :short => '-l', :default => DEFAULT_LOG_PATH
            opt :pid, "The path for the PID file", :type => String, :default => DEFAULT_PID_PATH
            opt :threads, "The number of threads", :type => Integer, :default => DEFAULT_NUMBER_OF_THREADS, :short => '-t'
          end
        when "status"
          Trollop::options do
            opt :pid, "The path for the PID file", :type => String, :default => DEFAULT_PID_PATH
          end
        when "stop"
          Trollop::options do
            opt :pid, "The path for the PID file", :type => String, :default => DEFAULT_PID_PATH
          end
        else
          Trollop::die "unknown command #{cmd.inspect}"
        end

      if cmd == 'start'
        unless options[:interactive]
          Trollop::die( :config, "is required when running as daemon" ) unless options[:config]
          Trollop::die( :log, "is required when running as daemon" ) unless options[:log]
          Trollop::die( :pid, "is required when running as daemon" ) unless options[:pid]
        end
      end

      if %w(restart status stop).include?( cmd )
        Trollop::die( :pid, "is required" ) unless options[:pid]
      end
    end

    def run
      send( cmd )
    end

  protected

    def start
      if options[:interactive]
        start_interactive
      else
        start_daemon
      end
    end

    def start_interactive
      server = RabbitWQ::Server.new( options.merge( log: nil ))
      server.start
    end

    def start_daemon
      server = RabbitWQ::ServerDaemon.new( options )
      server.start
    end

    def stop
      server = RabbitWQ::ServerDaemon.new( options )
      server.stop
    end

    def restart
      stop
      start_daemon
    end

    def status
      RabbitWQ::ServerDaemon.new( options ).status
    end

  end
end
