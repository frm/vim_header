module VimHeader
    class FileParser
        attr_accessor :functions
        FUNCTION_LINE = /^(?!static)\w+.*\s?{.*$/
        FUNCTION_BREAK_LINE = /^{.*$/
        FUNCTION_LINE_NO_PAR = /^(?!static)\w+.*$/

        def initialize(filename = nil)
            @functions = Array.new      # Array of functions to write in a header file
            @brackets = 0               # nr of active brackets
            @filename = filename || ""
        end

        def parse_file(filename)
            @filename = filename
            self.parse
        end

        def parse
            previous_line = ""
            File.open(@filename, "r").each_line do |line|
                line = line.chomp
                unless line.empty?
                    self.test_lines(line, previous_line)
                    previous_line = line
                    @brackets += self.count_parenthesis(line)
                end
            end
        end


        protected

        def test_lines(line, previous_line)
            if (@brackets == 0 && line =~ FileParser::FUNCTION_LINE)
                self.add_function(line)

            elsif(@brackets == 0 && line =~ FileParser::FUNCTION_BREAK_LINE)
                self.add_function(previous_line) if previous_line =~ FileParser::FUNCTION_LINE_NO_PAR
            end
        end

        def count_parenthesis(line)
            line.split(//).inject(0) do |result, c|
                if (c == '{')
                    result += 1
                elsif (c == '}')
                    result -= 1
                end

                result
            end
        end

        def add_function(line)
            new_line = ""
            i = 0
            while line[i] != '{' && i < line.length do
                new_line << line[i]
                i += 1
            end

            @functions.push(new_line)
        end

    end
end

if __FILE__ == $0
    class App
        def initialize(filename)
            @filename = filename
        end

        def run
            x = gets.chomp
            parsed = VimHeader::FileParser.new(x)
            parsed.parse
            parsed.functions.each{ |f| puts f }
        end
    end

    App.new(ARGV).run
end


