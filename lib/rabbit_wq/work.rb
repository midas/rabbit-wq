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

      if delay
        with_channel do |channel|
          delay_x = channel.direct( "#{RabbitWQ.configuration.delayed_exchange_prefix}-#{delay}ms", durable: true )
          work_x  = channel.direct( RabbitWQ.configuration.work_exchange, durable: true )

          channel.queue( "#{RabbitWQ.configuration.delayed_queue_prefix}-#{delay}ms",
                         durable: true,
                         arguments: { "x-dead-letter-exchange" => work_x.name,
                                      "x-message-ttl" => delay } ).
                  bind( delay_x )

          delay_x.publish( payload, durable: true,
                                    content_type: 'application/yaml',
                                    headers: options )
        end

        return
      end

      with_work_exchange do |work_x, work_q|
        work_x.publish( payload, durable: true,
                                 content_type: 'application/yaml',
                                 headers: options )
      end
    end

    def self.enqueue_error_payload( payload, options={} )
      with_channel do |channel|
        error_q = channel.queue( RabbitWQ.configuration.error_queue, durable: true )
        error_q.publish( payload, durable: true,
                                  content_type: 'application/yaml',
                                  headers: options )
      end
    end

    def self.with_work_exchange
      with_channel do |channel|
        begin
          exchange = channel.direct( RabbitWQ.configuration.work_exchange, durable: true )
          channel.queue( RabbitWQ.configuration.work_queue, durable: true ).tap do |q|
            q.bind( exchange )
            yield exchange, q
          end
        ensure
        end
      end
    end

    def self.with_channel
      Bunny.new.tap do |b|
        b.start
        begin
          b.create_channel.tap do |c|
            yield c
          end
        ensure
          b.stop
        end
      end
    end

    #def self.with_exchange
      #Bunny.new.tap do |b|
        #b.start
        #begin
          #b.create_channel.tap do |c|
            #queue = c.queue( 'replication', durable: true )
            #yield c.default_exchange, queue.name
          #end
        #ensure
          #b.stop
        #end
      #end
    #end

  end
end
