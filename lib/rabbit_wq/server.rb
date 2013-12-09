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
      @work_exchange ||= channel.direct( WORK_EXCHANGE, durable: true )
    end

    def work_queue
      @work_queue ||= channel.queue( QUEUE,
                                     durable: true ).
                              bind( work_exchange )
    end

    def pool
      @pool ||= MessageHandler.pool( size: options[:threads] )
    end

    def run
      if options[:threads] == 1
        Celluloid::Actor[:message_handler] = MessageHandler.new
      end

      @work_consumer = work_queue.subscribe( manual_ack: true ) do |delivery_info, metadata, payload|
        info "LISTENER RECEIVED #{payload}"

        if options[:threads] > 1
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

    def configure_server
      initialize_loggers
    end

  end
end
