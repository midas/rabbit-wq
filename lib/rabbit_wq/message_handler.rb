require 'celluloid/autostart'
require 'servitude'
require 'yaml'

module RabbitWQ
  class MessageHandler

    include Celluloid
    include Queues
    include Servitude::Logging
    include WorkLogging

    REQUEUE = true

    def call( options )
      Time.zone = Servitude.configuration.time_zone

      channel       = options[:channel]
      delivery_info = options[:delivery_info]
      metadata      = options[:metadata]
      payload       = options[:payload]

      worker = deserialize_worker( payload )
      info Rainbow( "WORKER [#{worker.object_id}] " + worker.inspect ).yellow
      handle_work( worker, payload )
      try_on_success_callback( worker )
      channel.ack delivery_info.delivery_tag
    rescue => e
      handle_error( worker, e, channel, delivery_info, payload, metadata )
    end

  protected

    def deserialize_worker( payload )
      YAML::load( payload ).tap do |worker|
        unless worker.is_a?( RabbitWQ::Worker )
          raise ArgumentError, "Worker of type #{worker.class.name} is not a valid worker (not a descendent of #{RabbitWQ::Worker.name})"
        end
      end
    rescue => e
      raise RabbitWQ::InvalidWorkError,
            "#{e.message} -- #{e.class.name}",
            e.backtrace
    end

    def handle_work( worker, payload )
      if ignore_and_trash?( worker )
        info "Trashed: #{worker.class.name}:#{worker.object_id}"
        return
      end

      if ignore_and_error?( worker )
        info "Ignored and sent to error queue: #{worker.class.name}:#{worker.object_id}"
        Work.enqueue_error_payload( payload, error: "Worker ignored" )
        return
      end

      unless worker.enabled?
        worker_info( worker, "Worker disabled" )
        if worker.error_on_disabled?
          Work.enqueue_error_payload( payload, error: "Worker disabled" )
        end
        return
      end

      worker.call
    end

    def handle_error( worker, e, channel, delivery_info, payload, metadata )
      headers = metadata[:headers] if metadata

      error_metadata = { type: e.class.name,
                         message: e.message,
                         backtrace: e.backtrace }

      if headers && headers['retry'] && !e.is_a?( RabbitWQ::FinalError )
        attempt = headers.fetch( 'attempt', 1 ).to_i

        if attempt < headers['retry']
          retry_delay = headers.fetch( 'retry_delay', 30000 )

          if retry_delay == 'auto-scale'
            retry_delay = retry_delays( attempt )
          end

          Work.enqueue_payload( payload, headers.merge( delay: retry_delay, attempt: attempt + 1 ).
                                                 merge( error: error_metadata ))
          error( e )
          worker_error( worker, "ERROR WITH RETRY " + error_metadata.inspect )
          try_on_error_callback( worker, e )
          try_on_retryable_error_callback( worker, e )
          channel.nack delivery_info.delivery_tag
          return
        end
      end

      if e.is_a?( RabbitWQ::FinalError ) && e.level != :error
        RabbitWQ.work_logger.send( e.level, worker, e.message )
        try_on_error_callback( worker, e )
        try_on_final_error_callback( worker, e )
        channel.nack delivery_info.delivery_tag
        return
      end

      Work.enqueue_error_payload( payload, error: error_metadata )
      error( e )
      worker_error( worker, "FINAL ERROR " + error_metadata.inspect )
      try_on_error_callback( worker, e )
      try_on_final_error_callback( worker, e )
      channel.nack delivery_info.delivery_tag
    end

    def try_on_success_callback( worker )
      return unless worker.respond_to?( :on_success )
      worker.on_success
    end

    def try_on_error_callback( worker, e )
      return unless worker.respond_to?( :on_error )
      worker.on_error( e )
    end

    def try_on_retryable_error_callback( worker, e )
      return unless worker.respond_to?( :on_retryable_error )
      worker.on_retryable_error( e )
    end

    def try_on_final_error_callback( worker, e )
      return unless worker.respond_to?( :on_final_error )
      worker.on_final_error( e )
    end

    def requeue( channel, delivery_info, e=nil )
      info Rainbow( 'REQUEUE ' + e.message ).yellow
      channel.reject delivery_info.delivery_tag, REQUEUE
    end

    def ignore_and_trash?( worker )
      config.ignored_workers_trash.include?( worker.class.name )
    end

    def ignore_and_error?( worker )
      config.ignored_workers_to_error_queue.include?( worker.class.name )
    end

    def config
      Servitude.configuration
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
