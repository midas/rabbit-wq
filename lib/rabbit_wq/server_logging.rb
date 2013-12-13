require 'yell'

# Provides logging services for the base server.
#
module RabbitWQ
  module ServerLogging

  protected

    def initialize_loggers
      RabbitWQ.logger = Yell.new do |l|
        l.level = log_level
        l.adapter $stdout, :level => [:debug, :info, :warn]
        l.adapter $stderr, :level => [:error, :fatal]
      end

      #Celluloid.logger = Yell.new do |l|
        #l.level = :info
        #l.adapter :file, File.join( File.dirname( options[:log] ), "#{APP_ID}-celluloid.log" )
      #end
    end

    def log_startup
      start_banner( options ).each do |line|
        RabbitWQ.logger.info line
      end
    end

    def start_banner( options )
      [
        "",
        "***",
        "* #{APP_NAME} started",
        "*",
        "* #{VERSION_COPYRIGHT}",
        "*",
        "* Configuration:",
        (options[:config_loaded] ? "*   file: #{options[:config]}" : nil),
        RabbitWQ::Configuration.attributes.map { |a| "*   #{a}: #{RabbitWQ.configuration.send( a )}" },
        "*",
        "***",
      ].flatten.reject( &:nil? )
    end

    def log_level
      options.fetch( :log_level, :info ).to_sym
    end

  end
end
