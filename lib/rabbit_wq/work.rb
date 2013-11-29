require 'bunny'

module RabbitWQ
  module Work

    def self.enqueue( worker, options={} )
      payload = worker.to_yaml
      enqueue_payload( payload, options )
    end

    def self.enqueue_payload( payload, options={} )
      delay = options.delete( :delay )
      delay = nil if delay && delay < 5000

      mq = ::Bunny.new.tap { |bunny| bunny.start }
      channel = mq.create_channel

      if delay
        delay_x = channel.direct( "#{DELAY_EXCHANGE_PREFIX}-#{delay}ms", durable: true )
        work_x  = channel.direct( WORK_EXCHANGE, durable: true )

        channel.queue( "#{DELAY_QUEUE_PREFIX}-#{delay}ms",
                       durable: true,
                       arguments: { "x-dead-letter-exchange" => work_x.name,
                                    "x-message-ttl" => delay } ).
                bind( delay_x )

        delay_x.publish( payload, durable: true,
                                  headers: options )
        return
      end

      work_q = channel.queue( QUEUE, durable: true )
      work_q.publish( payload, durable: true,
                               headers: options )
    end


  end
end
