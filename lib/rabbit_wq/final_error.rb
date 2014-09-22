module RabbitWQ
  class FinalError < StandardError

    attr_reader :level

    def initialize( level=:error )
      @level = level
    end

  end
end
