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
        threads
        time_zone
        work_exchange
        work_log_level
        work_log_path
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

    def work_log_level
      @work_log_level || 'info'
    end

    def work_log_path
      @work_log_path || '/var/log/rabbit-wq/rabbit-wq-work.log'
    end

    def work_queue
      @work_queue || 'work'
    end

  end
end
