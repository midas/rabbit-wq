module RabbitWQ
  module Worker

    def self.included( other_module )
      other_module.class_eval do
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
              RabbitWQ.work_logger.send level, self, message
            end
          end

        end
      end
    end

    def work( options={} )
      RabbitWQ::Work.enqueue( self, options )
      self
    end

    def with_logging
      info "BEGIN #{self.class.name}"
      yield
      info "END #{self.class.name}"
    end

  end
end
