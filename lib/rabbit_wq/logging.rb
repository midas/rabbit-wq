module RabbitWq
  module Logging

    %w(
      debug
      error
      fatal
      info
      warn
    ).each do |level|

      define_method level do |*messages|
        messages.each do |message|
          RabbitWq.logger.send level, message
        end
      end

    end

  end
end
