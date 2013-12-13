class ANSI

  def self.resolve_text( color, &block )
    text = nil
    if block_given?
      text = block.call + reset
    end
    "\e[#{chart[color.to_sym]}m#{text}"
  end

  def self.reset
    "\e[0m"
  end

  def self.chart
    {
      black: 30,
      red: 31,
      green: 32,
      yellow: 33,
      blue: 34,
      magenta: 35,
      cyan: 36,
      white: 37
    }
  end

  chart.keys.each do |color|

    define_singleton_method color do |&block|
      resolve_text color, &block
    end

  end

end
