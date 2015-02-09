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
        c.prefetch( config.prefetch )
      end
    end

  end
end
