require 'servitude'

module RabbitWQ
  class Cli < ::Servitude::Cli::Service

    no_commands do

      def configuration_class
        RabbitWQ::Configuration
      end

      def host_namespace
        RabbitWQ
      end

    end

  end
end
