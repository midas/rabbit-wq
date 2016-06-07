require 'optparse'
require 'rails'

module RabbitWQ
  class Command

    attr_reader :options

    def initialize( args )
      @options = {
        :quiet => true,
        :pid_dir => "#{Rails.root}/tmp/pids"
      }

      opts = OptionParser.new do |opts|
        opts.banner = "Usage: #{File.basename($0)} [options] start|stop|restart"

        opts.on('-h', '--help', 'Show this message') do
          puts opts
          exit 1
        end
        opts.on('--pid-dir=DIR', 'Specifies an alternate directory in which to store the process ids.') do |dir|
          @options[:pid_dir] = dir
        end
        opts.on('-i', '--interactive', 'Start the process in interactive mode.') do |n|
          @options[:interactive] = true
        end
      end

      @args = opts.parse!( args )
    end

    def start
      if options[:interactive]
        start_interactive( options )
      else
        start_daemonized( options )
      end
    end

    def start_interactive( options )
      server = RabbitWQ::Server.new( options.merge( log: nil ))
      server.start
    end

    def start_daemonized( options )
    end

  end
end
