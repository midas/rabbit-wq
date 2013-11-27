require 'celluloid/autostart'

module BrerRabbit
  class MessageHandler

    include Celluloid
    include Logging

    REQUEUE = true

    def call( options )
      channel       = options[:channel]
      delivery_info = options[:delivery_info]
      metadata      = options[:metadata]
      payload       = options[:payload]

      info "PAYLOAD ARRIVED #{payload}"
      channel.ack delivery_info.delivery_tag
    end

  protected

    def requeue( channel, delivery_info, e=nil )
      info ANSI.yellow { 'REQUEUE ' + e.message }
      channel.reject delivery_info.delivery_tag, REQUEUE
    end

  end
end
