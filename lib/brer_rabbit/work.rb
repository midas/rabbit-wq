require 'bunny'

module BrerRabbit
  module Work

    def self.enqueue( worker, options={} )
      options[:delay] = nil if options[:delay] && options[:delay] < 5000

      mq = ::Bunny.new.tap { |bunny| bunny.start }
      channel = mq.create_channel

      if options[:delay]
        delay_x = channel.direct( "#{DELAY_EXCHANGE_PREFIX}-#{options[:delay]}ms", durable: true )
        work_x = channel.direct( WORK_EXCHANGE, durable: true )
        queue = channel.queue( "#{DELAY_QUEUE_PREFIX}-#{options[:delay]}ms",
                               durable: true,
                               arguments: { "x-dead-letter-exchange" => work_x.name,
                                            "x-message-ttl" => options[:delay] } ).
                        bind( delay_x )

        delay_x.publish( 'hello', durable: true )
        return
      end

      work_q = channel.queue( QUEUE, durable: true )
      work_q.publish( 'hello', durable: true )
    end

  end
end
