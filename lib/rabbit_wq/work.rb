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
          delay_x = channel.direct( "#{config.delayed_exchange_prefix}-#{delay}ms", durable: true )

          work_x = channel.send( config.work_exchange_type,
                                 config.work_exchange,
                                 durable: true )

          channel.queue( "#{config.delayed_queue_prefix}-#{delay}ms",
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
        error_q = channel.queue( config.error_queue, durable: true )
        error_q.publish( payload, durable: true,
                                  content_type: 'application/yaml',
                                  headers: options )
      end
    end

    def self.with_work_exchange
      with_channel do |channel|
        begin
          exchange = channel.send( config.work_exchange_type,
                                   config.work_exchange,
                                   durable: true )

          channel.queue( config.work_queue, durable: true ).tap do |q|
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

    def self.config
      RabbitWQ.configuration
    end

  end
end
