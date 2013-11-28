require "rabbit_wq/version"

module RabbitWQ

  APP_ID                = "rabbit-wq"
  APP_NAME              = "Rabbit Work Queue"
  DELAY_QUEUE_PREFIX    = "work-delay" # TODO: Make this configurable (from ENV, or file?)
  DELAY_EXCHANGE_PREFIX = "work-delay" # TODO: Make this configurable (from ENV, or file?)
  ERROR_QUEUE           = "work-error"
  INT                   = "INT"
  QUEUE                 = "work" # TODO: Make this configurable (from ENV, or file?)
  VERSION_COPYRIGHT     = "v#{VERSION} \u00A9#{Time.now.year}"
  WORK_EXCHANGE         = "work" # TODO: Make this configurable (from ENV, or file?)

  autoload :Command,        'rabbit_wq/command'
  autoload :Configuration,  'rabbit_wq/configuration'
  autoload :Logging,        'rabbit_wq/logging'
  autoload :Queues,         'rabbit_wq/queues'
  autoload :MessageHandler, 'rabbit_wq/message_handler'
  autoload :Server,         'rabbit_wq/server'
  autoload :ServerLogging,  'rabbit_wq/server_logging'
  autoload :Work,           'rabbit_wq/work'

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield( configuration ) if block_given?
  end

  class << self
    attr_accessor :logger
  end

end
