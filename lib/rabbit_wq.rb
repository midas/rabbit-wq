require 'autoloaded'
require 'rainbow'
require 'servitude'

module RabbitWQ

  Autoloaded.module do |autoloading|
    autoloading.with :VERSION
  end

  include Servitude::Base

  def self.perform_boot
    author = 'C. Jason Harrelson'

    years = 2013
    years = "#{years}–#{::Time.now.year}" if years < ::Time.now.year

    boot app_name:            'Rabbit WQ',
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
  end

  perform_boot

end
