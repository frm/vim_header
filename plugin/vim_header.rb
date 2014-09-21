#!/bin/env ruby

module VimHeader
  class Parser
    # Regex constants
    # Tests line to see if it contains a function declaration
    FUNCTION_LINE = /^\s?(?!static)\w+.*\s?{.*$/
    # Tests line for paragraph break case:
    # int add(int x, int y)
    # {
    FUNCTION_BREAK_LINE = /^{.*$/
    # Tests if the function declaration falls in the previous case
    FUNCTION_LINE_NO_PAR = /^\s?(?!static)\w+.*$/

    def initialize(filename)
      # Array of functions to be written in a header file
      @functions = []
      # Array of CPP directives to be written in the header file
      @directives = []
      # We need to count the nestings.
      # Nestings are comments and functions
      # If we ever find a /* or {, we update the count
      # When we find the closing match, we decrement.
      # That way, it is garanteed that the function will only be added if it is not nested nor commented
      @nestings = 0
      @filename = filename
    end

    # Returns the corresponding header file
    def header_file
      @filename.gsub(".c", ".h")
    end

    # Creates new directives to be exported into a new .h
    # Although I don't like returning a almost hard-coded array,
    # It is pretty much necessary, since the export function iterates over an array
    # Also, the header files for a new .h act as template.
    # Consider this function the preparation for a template export in a valid format.
    def new_directives
      directive_file = header_file.upcase.gsub(".", "_") + "_"
      @directives = ["#ifndef #{directive_file}\n", "#define #{directive_file}\n\n"]
    end

    def update_directives
      File.open(header_file, "r").each_line do |line|
        # The algorithm does not account for empty lines.
        # I like to have paragraphs between my declarations, so we need to strip them and jump over then
        if line.strip.length > 0
          # Push it into the directives array if it is a CPP directive
          @directives.push(line) if line.include?("#")
          # Stop if we have reached a function declaration
          break if line =~ FUNCTION_LINE_NO_PAR
        end
      end
    end

    def parse
      previous_line = ""
      File.open(@filename, "r").each_line do |line|
        line = line.strip
        unless line.empty?
          # Both lines need to be tested. The previous line contextualizes the current one.
          # Example:
          # int add(int x, int y)
          # {
          # Should also count as a function to be exported.
          # However, we need the previous line to determine the context.
          test_lines(line, previous_line)
          # Moves forward in the file
          previous_line = line
          # Updates the nesting count
          count_nestings(line)
        end
      end
    end

    # In this stage, the file has already been parsed.
    # However, we need to check if we are overriding a .h file.
    # If not, we just generate new CPP directives
    # Otherwise, we need to copy them over, since the programmer might have added useful includes
    def export
      File.exists?(header_file) ? update_directives : new_directives
      export_file
    end

  protected
    # Checks the content of the lines to determine if they should be added to the functions array
    def test_lines(line, previous_line)
      # Functions should only be added when the nesting count is 0
      # See initialize
      if @nestings == 0
        case line
        # If it is a simple function declaration, we add it
        when FUNCTION_LINE
          add_function(line)
        # If it is a break line function, we only add if the previous line has the function declaration
        # int add(int x, int y)
        # {
        when FUNCTION_BREAK_LINE
          add_function(previous_line) if previous_line =~ FUNCTION_LINE_NO_PAR
        end
      end
    end

    # The best approach was a C-ish ugly one...
    # We iterate through each character of the string
    # If we find a opening comment or a opening bracket, opening count
    # If we find a closing comment or a closing bracket, decrement count
    # See initialize
    def count_nestings(line)
      line.split("").each_with_index do |char, index|
        next_char = index + 1 >= line.length ? nil : line[index + 1]
        @nestings += 1 if char == '{' || ( !(next_char.nil?) && char == '/' && next_char == '*' )
        @nestings -= 1 if char == '}' || ( !(next_char.nil?) && char == '*' && next_char == '/' )
      end
    end

    # Receives a line and strips it from unimportant content
    # Then, adds it to the functions array
    # I didn't use a each loop here.
    # As weird as it may seem, I prefered while
    # I have this thing against breaking a loop
    # Between using an each with break if it is a closing bracket or using a while
    # I'll go with the latter
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

    # Exports the directives and the functions into the header file
    def export_file
      file = File.open(header_file, "w")
      @directives.each { |d| file.write(d) }
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
      fp = VimHeader::Parser.new(@filename)
      fp.parse
      fp.export
    end
  end

 App.new(ARGV[0]).run

end


