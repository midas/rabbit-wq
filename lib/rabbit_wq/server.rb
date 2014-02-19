require 'bunny'
require 'celluloid/autostart'

module RabbitWQ
  class Server

    include Logging
    include Queues
    include ServerLogging

    attr_reader :options,
                :work_consumer,
                :work_exchange

    def initialize( options )
      @options = options

      configure_server
    end

    def start
      log_startup
      run

      trap( INT ) { finalize; exit }
      sleep
    end

  protected

    def finalize
      info "SHUTTING DOWN"
      work_consumer.cancel
      mq.close
    end

    def work_exchange
      @work_exchange ||= channel.send( config.work_exchange_type,
                                       config.work_exchange, durable: true )
    end

    def work_subscribe_queue
      @work_subscribe_queue ||= channel.queue( config.work_subscribe_queue,
                                               durable: true ).
                                        bind( work_exchange )
    end

    def pool
      @pool ||= MessageHandler.pool( size: threads )
    end

    def run
      if threads == 1
        Celluloid::Actor[:message_handler] = MessageHandler.new
      end

      @work_consumer = work_subscribe_queue.subscribe( manual_ack: true ) do |delivery_info, metadata, payload|
        info "LISTENER RECEIVED #{payload}"

        if threads > 1
          pool.async.call( payload: payload,
                           delivery_info: delivery_info,
                           metadata: metadata,
                           channel: channel )
        else
          message_handler.call( payload: payload,
                                delivery_info: delivery_info,
                                metadata: metadata,
                                channel: channel )
        end
      end
    end

    def message_handler
      Celluloid::Actor[:message_handler]
    end

    def threads
      config.threads
    end

    def config
      RabbitWQ.configuration
    end

    def configure_server
      load_configuration
      initialize_loggers
      load_environment
      resolve_threads
    end

    def load_configuration
      if File.exists?( options[:config] )
        options[:config_loaded] = true
        Configuration.from_file( options[:config] )
      end
    end

    def load_environment
      unless environment_file_path &&
        File.exists?( environment_file_path )
        return
      end

      ENV['RAILS_ENV'] = ENV['RACK_ENV'] = config.env
      require environment_file_path
    end

    def resolve_threads
      if options[:threads]
        RabbitWQ.configuration.threads = options[:threads]
      end

      return if RabbitWQ.configuration.threads

      RabbitWQ.configuration.threads = 1
    end

    def environment_file_path
      RabbitWQ.configuration.environment_file_path
    end

  end
end
