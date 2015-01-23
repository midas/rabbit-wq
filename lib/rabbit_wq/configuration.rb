require 'servitude'

module RabbitWQ
  class Configuration < Servitude::Configuration

    def self.defaults
      {
        delayed_exchange_prefix: 'work-delay',
        delayed_queue_prefix: 'work-delay',
        env: 'production',
        error_queue: 'work-error',
        time_zone: 'UTC',
        work_exchange: 'work',
        work_exchange_type: 'fanout',
        work_log_level: 'info',
        work_log_path: '/var/log/rabbit-wq/rabbit-wq-work.log',
        work_publish_queue: 'work',
        work_subscribe_queue: 'work'
      }
    end

  end
end
