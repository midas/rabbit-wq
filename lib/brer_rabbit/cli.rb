require 'rubygems'
require 'brer_rabbit'
require 'trollop'
require 'yell'

module BrerRabbit
  module Cli

    SUB_COMMANDS = %w(
      restart
      start
      status
      stop
    )

    def self.start( options )
      if options[:interactive]
        start_interactive options
      else
        start_daemon options
      end
    end

    def self.start_interactive( options )
      server = BrerRabbit::Server.new( options.merge( log: nil ) )
      server.start
    end

    def self.start_daemon( options )
      server = BrerRabbit::ServerDaemon.new( options )
      server.start
    end

  end
end

DEFAULT_LOG_PATH = "/var/log/rabbit/#{BrerRabbit::APP_ID}.log"
DEFAULT_PID_PATH = "/var/run/rabbit/#{BrerRabbit::APP_ID}.pid"

global_opts = Trollop::options do
  version BrerRabbit::VERSION_COPYRIGHT
  banner <<-EOS
#{BrerRabbit::APP_NAME} #{BrerRabbit::VERSION_COPYRIGHT}

Usage:
  #{BrerRabbit::APP_ID} [command] [options]

  commands:
#{BrerRabbit::Cli::SUB_COMMANDS.map { |cmd| "    #{cmd}" }.join( "\n" )}

  (For help with a command: #{BrerRabbit::APP_ID} [command] -h)

options:
EOS
  stop_on BrerRabbit::Cli::SUB_COMMANDS
end

# Get the sub-command and its options
#
cmd = ARGV.shift || ''
cmd_opts = case( cmd )
  #when "restart"
    #Trollop::options do
      #opt :pid, "The path for the PID file", :type => String, :default => DEFAULT_PID_PATH
    #end
  when "start"
    Trollop::options do
      opt :interactive, "Execute the server in interactive mode", :short => '-i'
      opt :log_level, "The log level", :type => String, :default => 'info'
      opt :log, "The path for the log file", :type => String, :short => '-l', :default => DEFAULT_LOG_PATH
      opt :pid, "The path for the PID file", :type => String, :default => DEFAULT_PID_PATH
    end
  #when "status"
    #Trollop::options do
      #opt :pid, "The path for the PID file", :type => String, :default => DEFAULT_PID_PATH
    #end
  #when "stop"
    #Trollop::options do
      #opt :pid, "The path for the PID file", :type => String, :default => DEFAULT_PID_PATH
    #end
  else
    Trollop::die "unknown command #{cmd.inspect}"
  end

if cmd == 'start'
  unless cmd_opts[:interactive]
    Trollop::die( :log, "is required when running as daemon" ) unless cmd_opts[:log]
    Trollop::die( :pid, "is required when running as daemon" ) unless cmd_opts[:pid]
  end
end

if %w(restart status stop).include?( cmd )
  Trollop::die( :pid, "is required" ) unless cmd_opts[:pid]
end

# Execute the command
#
case cmd
  when "restart"
    BrerRabbit::ServerDaemon.new( cmd_opts ).restart
  when "start"
    BrerRabbit::Cli.start cmd_opts
  when "status"
    BrerRabbit::ServerDaemon.new( cmd_opts ).status
  when "stop"
    BrerRabbit::ServerDaemon.new( cmd_opts ).stop
  end
