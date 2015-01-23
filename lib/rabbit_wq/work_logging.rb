require 'yell'

module RabbitWQ
  module WorkLogging

    %w(
      debug
      error
      fatal
      info
      warn
    ).each do |level|

      define_method "worker_#{level}" do |worker, *messages|
        return unless RabbitWQ.work_logger
        messages.each do |message|
          RabbitWQ.work_logger.send level, worker, message
        end
      end

    end

  end
end
