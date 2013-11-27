require 'bunny'

module BrerRabbit
  class Server

    include ServerLogging
    include Logging

    attr_reader :message_consumer,
                :options,
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
      message_consumer.cancel
      mq.close
    end

    def mq
      @mq ||= ::Bunny.new.tap do |bunny|
        bunny.start
      end
    end

    def channel
      @channel ||= mq.create_channel
    end

    def work_exchange
      @work_exchange ||= channel.direct( WORK_EXCHANGE, durable: true )
    end

    def queue
      @queue ||= channel.queue( QUEUE,
                                durable: true ).
                         bind( work_exchange )
    end

    def pool
      @pool ||= MessageHandler.pool( size: options[:pool_size] )
    end

    def run
      @message_consumer = queue.subscribe( manual_ack: true ) do |delivery_info, metadata, payload|
        debug "LISTENER RECEIVED #{payload}"

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
