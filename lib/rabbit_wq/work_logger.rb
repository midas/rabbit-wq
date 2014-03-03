require 'ansi'
require 'yell'

module RabbitWQ
  class WorkLogger

    def initialize( log_level, path )
      @logger = Yell.new do |l|
                  l.level = log_level
                  l.adapter :file, path
                end
    end

    def level=( level )
      # conform to API but do not set log level this way
    end

    %w(
      debug
      error
      fatal
      info
      warn
    ).each do |level|

      define_method level do |*args|
        worker, message = nil, nil
        if args.size > 1
          worker, message = *args
        else
          message = args.first
        end

        if worker
          logger.send( level, "[" + ANSI.cyan { "#{worker.class.name}:#{worker.object_id}" } + "] #{message}" )
        else
          logger.send( level, message )
        end
      end

    end

  protected

    attr_reader :logger

  end
end
