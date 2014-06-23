module VimHeader
    class FileParser
        attr_accessor :functions
        FUNCTION_LINE = /^\s?(?!static)\w+.*\s?{.*$/
        FUNCTION_BREAK_LINE = /^{.*$/
        FUNCTION_LINE_NO_PAR = /^\s?(?!static)\w+.*$/

        # Class methods

        # Creates an array of cpp directives contained in a header file
        def self.name_directives(filename)
            directive_filename = filename.upcase.gsub(".", "_") + "_"
            directives = Array.new
            directives.push("#ifndef " + directive_filename + "\n")
            directives.push("#define " + directive_filename + "\n\n")

            directives
        end

        def self.directives_from_file(filename)
            directives = Array.new
            File.open(filename, "r").each_line do |line|
                directives.push(line) if line.include?("#")
                break if line =~ FileParser::FUNCTION_LINE_NO_PAR
            end

            directives
        end

        def self.get_header_name(filename)
            filename.gsub(".c", ".h")
        end


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
                line = line.strip
                unless line.empty?
                    self.test_lines(line, previous_line)
                    previous_line = line
                    @brackets += self.count_parenthesis(line)
                end
            end
        end

        def export
            header_file = FileParser.get_header_name(@filename)
            if File.exists?(header_file)
                cpp_directives = FileParser.directives_from_file(header_file)
            else
                cpp_directives = FileParser.name_directives(header_file)
            end

            export_file(cpp_directives, header_file)
        end

        protected

        def test_lines(line, previous_line)
            if (@brackets == 0 && line =~ FileParser::FUNCTION_LINE)
                self.add_function(line)

            elsif(@brackets == 0 && line =~ FileParser::FUNCTION_BREAK_LINE)
                self.add_function(previous_line) if previous_line =~ FileParser::FUNCTION_LINE_NO_PAR
            end
        end

        # This version includes commented lines in the header
        def count_parenthesis2(line)
            line.split(//).inject(0) do |result, c|
                if (c == '{')
                    result += 1
                elsif (c == '}')
                    result -= 1
                end

                result
            end
        end

        def count_parenthesis(line)
            i = 0
            count = 0

            while i < line.length do

                c1 = line[i]
                c2 = i + 1 >= line.length ? nil : line[i+1]

                count += 1 if c1 == '{' || ( !(c2.nil?) && c1 == '/' && c2 == '*' )
                count -= 1 if c1 == '}' || ( !(c2.nil?) && c1 == '*' && c2 == '/' )

                i += 1
            end

            count
        end

        def add_function(line)
            new_line = ""
            i = 0
            while line[i] != '{' && i < line.length do
                new_line << line[i]
                i += 1
            end
            new_line = new_line.strip + ";\n\n"
            @functions.push(new_line)
        end

        def export_file(directives, filename)
            file = File.open(filename, "w")
            directives.each { |d| file.write(d) }
            @functions.each { |f| file.write(f) }
            file.write("#endif")
        end
    end
end

if __FILE__ == $0
    class App
        def initialize(filename)
            @filename = filename
        end

        def run
            x = gets.strip
            parsed = VimHeader::FileParser.new(x)
            parsed.parse
            parsed.functions.each{ |f| puts f }
            parsed.export
        end
    end

    App.new(ARGV).run
end


