require "brer_rabbit/version"

module BrerRabbit

  APP_ID                = "brer-rabbit"
  APP_NAME              = "Rabbit Work Queue"
  COMPANY               = "Look Forward Enterprises"
  DELAY_QUEUE_PREFIX    = "work-delay" # TODO: Make this configurable (from ENV, or file?)
  DELAY_EXCHANGE_PREFIX = "work-delay" # TODO: Make this configurable (from ENV, or file?)
  INT                   = "INT"
  QUEUE                 = "work" # TODO: Make this configurable (from ENV, or file?)
  VERSION_COPYRIGHT     = "v#{VERSION} \u00A9#{Time.now.year} #{COMPANY}"
  WORK_EXCHANGE         = "work" # TODO: Make this configurable (from ENV, or file?)

  autoload :Configuration,  'brer_rabbit/configuration'
  autoload :Logging,        'brer_rabbit/logging'
  autoload :MessageHandler, 'brer_rabbit/message_handler'
  autoload :Server,         'brer_rabbit/server'
  autoload :ServerLogging,  'brer_rabbit/server_logging'
  autoload :Work,           'brer_rabbit/work'

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
