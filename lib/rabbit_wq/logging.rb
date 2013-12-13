require 'yell'

module RabbitWQ
  module Logging

    %w(
      debug
      error
      fatal
      info
      warn
    ).each do |level|

      define_method level do |*messages|
        return unless RabbitWQ.logger
        messages.each do |message|
          RabbitWQ.logger.send level, message
        end
      end

      define_method "worker_#{level}" do |worker, *messages|
        return unless RabbitWQ.work_logger
        messages.each do |message|
          RabbitWQ.work_logger.send level, worker, message
        end
      end

    end

  end
end
