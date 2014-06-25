#!/bin/env ruby

module VimHeader
    class FileParser
        FUNCTION_LINE = /^\s?(?!static)\w+.*\s?{.*$/
        FUNCTION_BREAK_LINE = /^{.*$/
        FUNCTION_LINE_NO_PAR = /^\s?(?!static)\w+.*$/

        # Class methods

        # Creates an array of CPP directive for a new header file
        # The file does must not exist already or the directives will be overriden
        def self.name_directives(filename)
            directive_filename = filename.upcase.gsub(".", "_") + "_"
            directives = Array.new
            directives.push("#ifndef " + directive_filename + "\n")
            directives.push("#define " + directive_filename + "\n\n")

            directives
        end

        # Creates an array of CPP directives contained in a header file
        # The method shall copy into the array all lines that include a '#'
        # It shall ignore lines that contain nothing but whitespaces
        def self.directives_from_file(filename)
            directives = Array.new
            File.open(filename, "r").each_line do |line|
                if line.strip.length > 0
                    directives.push(line) if line.include?("#")
                    break if line =~ FileParser::FUNCTION_LINE_NO_PAR
                end
            end

            directives
        end

        # Returns the header filename
        def self.get_header_name(filename)
            filename.gsub(".c", ".h")
        end


        def initialize(filename = nil)
            @functions = Array.new      # Array of functions to write in a header file
            @brackets = 0               # Nr of active brackets. For algorithm purposes, comments count as brackets
            @filename = filename || ""
        end

        # Parses a given filename
        def parse_file(filename)
            @filename = filename
            self.parse
        end

        # Parsing function
        # Shall test every line for functions
        def parse
            previous_line = ""
            File.open(@filename, "r").each_line do |line|
                line = line.strip
                unless line.empty?
                    self.test_lines(line, previous_line)
                    previous_line = line
                    @brackets += self.count_brackets(line)
                end
            end
        end

        # Exports the current .c file into a corresponding .h
        # It starts by building the CPP directives and then export every function
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

        # Shall look into the contents of a given line, seeing if itself contains a function or delimits a function to the previous
        def test_lines(line, previous_line)
            if (@brackets == 0 && line =~ FileParser::FUNCTION_LINE)
                self.add_function(line)

            elsif(@brackets == 0 && line =~ FileParser::FUNCTION_BREAK_LINE)
                self.add_function(previous_line) if previous_line =~ FileParser::FUNCTION_LINE_NO_PAR
            end
        end

        # Counts the open/closed brackets in a given line
        def count_brackets(line)
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

        # Receives a file line and extracts the function header contained in such
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

        # Exports the directives and the functions into a .h file
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
            fp = VimHeader::FileParser.new(@filename)
            fp.parse
            fp.export
        end
    end

    App.new(ARGV[1]).run
end


