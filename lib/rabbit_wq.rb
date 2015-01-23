require 'rainbow'
require 'servitude'
require 'rabbit_wq/version'

module RabbitWQ

  include Servitude::Base

  autoload :Command,        'rabbit_wq/command'
  autoload :Cli,            'rabbit_wq/cli'
  autoload :Configuration,  'rabbit_wq/configuration'
  autoload :FinalError,     'rabbit_wq/final_error'
  autoload :Queues,         'rabbit_wq/queues'
  autoload :MessageHandler, 'rabbit_wq/message_handler'
  autoload :Server,         'rabbit_wq/server'
  autoload :Work,           'rabbit_wq/work'
  autoload :Worker,         'rabbit_wq/worker'
  autoload :WorkLogger,     'rabbit_wq/work_logger'
  autoload :WorkLogging,    'rabbit_wq/work_logging'

  def self.perform_boot
    author = 'C. Jason Harrelson'

    years = 2013
    years = "#{years}–#{::Time.now.year}" if years < ::Time.now.year

    boot host_namespace:      self,
         app_name:            'Rabbit WQ',
         author:              author,
         attribution:         "v#{VERSION} Copyright © #{years} #{author}",
         default_config_path: "/etc/rabbit-wq/#{process_name}.conf",
         use_config:          true
  end

  def self.process_name
    'rabbit-wq'
  end

  class << self
    attr_accessor :work_logger
    #attr_accessor :logger,
                  #:work_logger
  end

end
