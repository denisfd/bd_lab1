#!/usr/bin/env ruby

require 'clamp'
require 'pry'

$LOAD_PATH << File.expand_path('./lib', __dir__)

require 'seed'
require 'client'

class SeedCommand < Clamp::Command
  def execute
    Seed.seed
  end
end


class TableCommand < Clamp::Command

  subcommand "print", "Prints table values" do

    option ["-n", "--name"], "Name", "Name of table to print"

    def execute
      tables = Client.tables
      unless name.nil?
        unless tables.include? name
          puts "Unknown table"
          return
        end
        print_table(name)
      else
        tables.each do |table|
          print_table(table)
        end
      end
    end
  end
end

def print_table(name)
  data = Client.all(name)
  return if data.length == 0

  puts "Table #{name.upcase.colorize(color: :green)}"
  print_row(data[0].keys)
  puts "-----".colorize(color: :yellow)
  data.each.with_index do |row, i|
    print_row(row.values, i)
  end
  puts "-----\n".colorize(color: :yellow)
end

def print_row(row, i = 0)
  puts row.map { |str|
    s = " #{str.to_s[0...30].gsub(/\s\w+\s*$/, '...')}".ljust(13)
      .colorize(color: :white, background: (i % 2 == 0) ? :light_black : :black)
  }.join("|".colorize(color: :yellow))
end

class Main < Clamp::Command
  subcommand 'seed', 'Drop schema and seed random values', SeedCommand
  subcommand 'table', 'Manipulate table data', TableCommand
end

Main.run