require 'celluloid/autostart'
require 'yaml'

module RabbitWQ
  class MessageHandler

    include Celluloid
    include Logging
    include Queues

    REQUEUE = true

    def call( options )
      Time.zone = RabbitWQ.configuration.time_zone

      channel       = options[:channel]
      delivery_info = options[:delivery_info]
      metadata      = options[:metadata]
      #headers       = metadata[:headers]
      payload       = options[:payload]

      debug "PAYLOAD ARRIVED #{payload}"

      worker = YAML::load( payload )
      info ANSI.yellow { "WORKER [#{worker.object_id}] " + worker.inspect }
      worker.call
      channel.ack delivery_info.delivery_tag
    rescue => e
      handle_error( worker, e, channel, delivery_info, payload, metadata )
    end

  protected

    def handle_error( worker, e, channel, delivery_info, payload, metadata )
      headers = metadata[:headers]

      error_metadata = { type: e.class.name,
                         message: e.message,
                         backtrace: e.backtrace }

      if headers['retry']
        attempt = headers.fetch( 'attempt', 1 ).to_i

        if attempt < headers['retry']
          retry_delay = headers.fetch( 'retry_delay', 30000 )

          if retry_delay == 'auto-scale'
            retry_delay = retry_delays( attempt )
          end

          Work.enqueue_payload( payload, headers.merge( delay: retry_delay, attempt: attempt + 1 ).
                                                 merge( error: error_metadata ))
          worker_error( worker, "ERROR WITH RETRY " + error_metadata.inspect )
          channel.nack delivery_info.delivery_tag
          return
        end
      end

      Work.enqueue_error_payload( payload, error: error_metadata )
      worker_error( worker, "FINAL ERROR " + error_metadata.inspect )
      channel.nack delivery_info.delivery_tag
      return
    end

    def requeue( channel, delivery_info, e=nil )
      info ANSI.yellow { 'REQUEUE ' + e.message }
      channel.reject delivery_info.delivery_tag, REQUEUE
    end

    def retry_delays( retry_num )
      {
        1 => 1,
        2 => 5,
        3 => 15,
        4 => 30,
        5 => 60,
        6 => 360, # 6 hrs
        7 => 720, # 12 hrs
        8 => 1440, # 24 hrs
        9 => 2880, # 48 hrs
      }[retry_num] * 60000
    end
  end
end
