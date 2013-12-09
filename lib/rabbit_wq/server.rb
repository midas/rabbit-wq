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
      options[:pool_size] ||= 2 # TODO move to external configuration

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
      @pool ||= MessageHandler.pool( size: options[:pool_size] )
    end

    def run
      @work_consumer = work_queue.subscribe( manual_ack: true ) do |delivery_info, metadata, payload|
        info "LISTENER RECEIVED #{payload}"

        pool.async.call( payload: payload,
                         delivery_info: delivery_info,
                         metadata: metadata,
                         channel: channel )
      end
    end

    def configure_server
      initialize_loggers
    end

  end
end
