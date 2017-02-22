module Ruby2JS
  class Converter

    # (if
    #   (true)
    #   (...)
    #   (...))

    handle :if do |condition, then_block, else_block|
      # return parse not condition if else_block and no then_block
      if else_block and not then_block
        return parse(s(:if, s(:not, condition), else_block, nil), @state) 
      end

      then_block ||= s(:nil)

      if @state == :statement
        begin
          scope, @scope = @scope, false
          mark = output_location

          # use short form when appropriate
          unless else_block or then_block.type == :begin
            put "if ("; parse condition; put ') '
            wrap { parse then_block, :statement }
          else
            put "if ("; parse condition; puts ') {'
            parse then_block, :statement
            sput '}'

            while else_block and else_block.type == :if
              condition, then_block, else_block = else_block.children
              put ' else if ('; parse condition; puts ') {'
              parse then_block, :statement
              sput '}'
            end

            if else_block
              puts ' else {'; parse else_block, :statement; sput '}'
            end
          end

          if scope
            vars = @vars.select {|key, value| value == :pending}.keys
            unless vars.empty?
              insert mark, "var #{vars.join(', ')}#{@sep}"
              vars.each {|var| @vars[var] = true}
            end
          end
        ensure
          @scope = scope
        end
      else
        else_block ||= s(:nil)
        put '('; parse condition; put ' ? '; parse then_block
        put ' : '; parse else_block; put ')'
      end
    end
  end
end
