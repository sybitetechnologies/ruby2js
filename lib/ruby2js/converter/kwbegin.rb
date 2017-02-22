module Ruby2JS
  class Converter

    # (rescue
    #   (send nil :a)
    #     (resbody nil nil
    #       (send nil :b)) nil)
    handle :rescue do |*statements|
      parse_all s(:kwbegin, s(:rescue, *statements))
    end

    # (kwbegin
    #   (ensure
    #     (rescue
    #       (send nil :a)
    #       (resbody nil nil
    #         (send nil :b)) nil)
    #    (send nil :c)))

    handle :kwbegin do |*children|
      block = children.first
      if block.type == :ensure
        block, finally = block.children
      else
        finally = nil
      end

      if block and block.type == :rescue
        body, *recovers, otherwise = block.children
        raise NotImplementedError, "block else" if otherwise

        if recovers.any? {|recover| not recover.children[1]}
          raise NotImplementedError, "recover without exception variable"
        end

        var = recovers.first.children[1]

        if recovers.any? {|recover| recover.children[1] != var}
          raise NotImplementedError, 
            "multiple recovers with different exception variables"
        end
      else
        body = block
      end

      if not recovers and not finally
        return parse s(:begin, *children)
      end

      puts "try {"; parse body, :statement; sput '}'

      if recovers
        if recovers.length == 1 and not recovers.first.children.first
          # single catch with no exception named
          put " catch ("; parse var; puts ") {"
          parse recovers.first.children.last, :statement; sput '}'
        else
          put " catch ("; parse var; puts ') {'

          first = true
          recovers.each do |recover|
            exceptions, var, recovery = recover.children

            if exceptions

              put "} else " if not first
              first = false

              put  'if ('
              exceptions.children.each_with_index do |exception, index|
                put ' || ' unless index == 0
                parse var; put ' instanceof '; parse exception
              end
              puts ') {'
            else
              puts '} else {'
            end

            parse recovery, :statement; puts ''
          end

          if recovers.last.children.first
            puts "} else {"; put 'throw '; parse var; puts ''
          end

          puts '}'; put '}'
        end
      end

      (puts ' finally {'; parse finally, :statement; sput '}') if finally
    end
  end
end
