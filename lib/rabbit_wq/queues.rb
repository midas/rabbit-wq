module RabbitWQ
  module Queues

  protected

    def mq
      @mq ||= ::Bunny.new.tap do |bunny|
        bunny.start
      end
    end

    def channel
      @channel ||= mq.create_channel.tap do |c|
        c.prefetch( 10 )
      end
    end

    #def work_exchange
      #@work_exchange ||= channel.direct( RabbitWQ.configuration.work_exchange, durable: true )
    #end

    #def work_queue
      #@work_queue ||= channel.queue( RabbitWQ.configuration.work_queue,
                                     #durable: true ).
                              #bind( work_exchange )
    #end

  end
end
