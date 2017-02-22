module Ruby2JS
  class Converter

    # (self)

    handle :self do
      if @block_depth and @block_depth > 1
        @block_this = true
        put 'self'
      else
        put 'this'
      end
    end
  end
end
