require 'servitude'

module RabbitWQ
  class Configuration < Servitude::Configuration

    def self.defaults
      {
        delayed_exchange_prefix: 'work-delay',
        delayed_queue_prefix: 'work-delay',
        env: 'production',
        error_queue: 'work-error',
        log: "/var/log/rabbit-wq/#{RabbitWQ.process_name}.log",
        log_level: 'info',
        pid: "/var/run/rabbit-wq/#{RabbitWQ.process_name}.pid",
        supervision_retry_timeout_in_seconds: 1,
        threads: 1,
        time_zone: 'UTC',
        work_exchange: 'work',
        work_exchange_type: 'fanout',
        work_log_level: 'info',
        work_log_path: '/var/log/rabbit-wq/rabbit-wq-work.log',
        work_publish_queue: 'work',
        work_subscribe_queue: 'work'
      }
    end

    def ignored_workers_to_error_queue
      return [] unless ignored_workers
      Array( ignored_workers.to_error_queue )
    end

    def ignored_workers_trash
      return [] unless ignored_workers
      Array( ignored_workers.trash )
    end

  end
end
