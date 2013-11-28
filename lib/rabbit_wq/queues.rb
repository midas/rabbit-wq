module RabbitWQ
  module Queues

  protected

    def mq
      @mq ||= ::Bunny.new.tap do |bunny|
        bunny.start
      end
    end

    def channel
      @channel ||= mq.create_channel
    end

    #def work_exchange
      #@work_exchange ||= channel.direct( WORK_EXCHANGE, durable: true )
    #end

    #def work_queue
      #@work_queue ||= channel.queue( QUEUE,
                                     #durable: true ).
                              #bind( work_exchange )
    #end

  end
end
