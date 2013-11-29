module RabbitWQ
  module Worker

    def work( options={} )
      RabbitWQ::Work.enqueue( self, options )
      self
    end

  end
end
