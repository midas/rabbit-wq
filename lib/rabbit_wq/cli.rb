require 'servitude'

module RabbitWQ
  class Cli < ::Servitude::Cli::Service

    no_commands do

      def configuration_class
        RabbitWQ::Configuration
      end

    end

  end
end
