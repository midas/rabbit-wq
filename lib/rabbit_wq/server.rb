require 'bunny'
require 'celluloid/autostart'

module RabbitWQ
  class Server

    include Servitude::Server
    include Servitude::ServerThreaded
    include Queues

    after_initialize :initialize_work_logger
    after_initialize :load_environment

    attr_reader :work_consumer,
                :work_exchange

    finalize do
      info 'Shutting down ...'

      work_consumer.cancel
      mq.close
    end

  protected

    def handler_class
      RabbitWQ::MessageHandler
    end

    def run
      @work_consumer = work_subscribe_queue.subscribe( manual_ack: true ) do |delivery_info, metadata, payload|
        with_supervision( delivery_info: delivery_info ) do
          debug( "#{Rainbow(  "LISTENER RECEIVED " ).magenta} #{payload}" )

          call_handler_respecting_thread_count( payload: payload,
                                                delivery_info: delivery_info,
                                                metadata: metadata,
                                                channel: channel )
        end
      end
    end

    def work_exchange
      @work_exchange ||= channel.send( config.work_exchange_type,
                                       config.work_exchange, durable: true )
    end

    def work_subscribe_queue
      @work_subscribe_queue ||= channel.queue( config.work_subscribe_queue,
                                               durable: true ).
                                        bind( work_exchange )
    end

    def error_queue
      channel.queue( config.error_queue, durable: true )
    end

    def warn_for_supevision_error
      warn( Rainbow(  "RETRYING due to waiting on supervisor to restart actor ..." ).cyan )
    end

    def warn_for_dead_actor_error
      warn( Rainbow(  "RETRYING due to Celluloid::DeadActorError ..." ).blue )
    end

    def log_error( e )
      parts = [Rainbow(  [e.class.name, e.message].join( ': ' ) ).red, format_backtrace( e.backtrace )]
      error( parts.join( "\n" ))
    end

    def handle_error( options, e )
      delivery_info = options[:delivery_info]
      log_error( e )
      #error_queue.publish( payload, headers: { exception_message: e.message,
                                               #exception_class: e.class.name,
                                               #exception_backtrace: e.backtrace } )
      debug( Rainbow(  "NACK" ).red + " #{e.message}" )
      channel.nack( delivery_info.delivery_tag )
    rescue => ex
      error( Rainbow(  "ERROR while handling error | #{ex.class.name} | #{ex.message} | #{ex.backtrace.inspect}" ).red )
    end

    def initialize_work_logger
      RabbitWQ.work_logger = WorkLogger.new( config.work_log_level,
                                             config.work_log_path )
    end

    def load_environment
      unless environment_file_path &&
        File.exists?( environment_file_path )
        raise "Environment file '#{environment_file_path}' does not exist"
      end

      ENV['RAILS_ENV'] = ENV['RACK_ENV'] = config.env
      require environment_file_path
    end

    #def config
      #RabbitWQ.configuration
    #end

    def environment_file_path
      config.environment_file_path
    end

  end
end
