require 'ansi'
require 'rabbit_wq/version'

module RabbitWQ

  APP_ID                = 'rabbit-wq'
  APP_NAME              = 'Rabbit Work Queue'
  INT                   = 'INT'
  VERSION_COPYRIGHT     = "v#{VERSION} \u00A9#{Time.now.year}"

  autoload :Command,        'rabbit_wq/command'
  autoload :Configuration,  'rabbit_wq/configuration'
  autoload :Logging,        'rabbit_wq/logging'
  autoload :Queues,         'rabbit_wq/queues'
  autoload :MessageHandler, 'rabbit_wq/message_handler'
  autoload :Server,         'rabbit_wq/server'
  autoload :ServerDaemon,   'rabbit_wq/server_daemon'
  autoload :ServerLogging,  'rabbit_wq/server_logging'
  autoload :Work,           'rabbit_wq/work'
  autoload :Worker,         'rabbit_wq/worker'
  autoload :WorkLogger,     'rabbit_wq/work_logger'

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configuration=( configuration )
    @configuration = configuration
  end

  def self.configure
    yield( configuration ) if block_given?
  end

  class << self
    attr_accessor :logger,
                  :work_logger
  end

end
