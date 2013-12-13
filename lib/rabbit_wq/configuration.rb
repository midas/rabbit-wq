require 'oj'

module RabbitWQ
  class Configuration

    def self.attributes
      %w(
        delayed_exchange_prefix
        delayed_queue_prefix
        environment_file_path
        env
        error_queue
        time_zone
        work_exchange
        work_queue
      )
    end

    attr_accessor( *attributes )

    def self.from_file( file_path )
      options = Oj.load( File.read( file_path ))
      RabbitWQ.configuration = Configuration.new

      attributes.each do |c|
        if options[c]
          RabbitWQ.configuration.send( :"#{c}=", options[c] )
        end
      end
    end

    def delayed_exchange_prefix
      @delayed_exchange_prefix || 'work-delay'
    end

    def delayed_queue_prefix
      @delayed_queue_prefix || 'work-delay'
    end

    def env
      @env || 'production'
    end

    def error_queue
      @error_queue || 'work-error'
    end

    def time_zone
      @time_zone || 'UTC'
    end

    def work_exchange
      @work_exchange || 'work'
    end

    def work_logger( log_level, path )
      return if RabbitWQ.work_logger

      RabbitWQ.work_logger = WorkLogger.new( log_level, path )
    end

    def work_queue
      @work_queue || 'work'
    end

  end
end
