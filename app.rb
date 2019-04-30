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
        data = Client.all(name)
        return if data.length.zero?
        print_table(name, data)
      else
        tables.each do |table|
          data = Client.all(table)
          next if data.length.zero?
          print_table(table, data)
        end
      end
    end
  end

  subcommand "insert", "Inserts new row to table" do

    def execute
      colored_tables = Client.tables.map.with_index do
        |str, i| "#{i.to_s.rjust(3)}. #{str}".colorize(color: :light_blue)
      end
      puts "Existing tables:".colorize(:light_green), colored_tables

      tables = Client.tables
      print "INSERT INTO: ".colorize(:yellow)
      choice = STDIN.gets.chomp
      unless tables.include? choice
        puts "Unknown table"
        return
      end

      values = {}
      Client.columns(choice).each do |column|
        print "#{column}: "
        value = STDIN.gets.chomp
        values[column] = value
      end

      Client.insert(choice, values)
    end
  end

  subcommand "update", "Updates rows in table" do

    def execute
      colored_tables = Client.tables.map.with_index do
        |str, i| "#{i.to_s.rjust(3)}. #{str}".colorize(color: :light_blue)
      end
      puts "Existing tables:".colorize(:light_green), colored_tables

      tables = Client.tables
      print "UPDATE: ".colorize(:yellow)
      choice = STDIN.gets.chomp
      unless tables.include? choice
        puts "Unknown table"
        return
      end

      where = read_column_values(choice, "WHERE:")
      set = read_column_values(choice, "SET:")

      Client.update(choice, set, where)
    end
  end

  subcommand "delete", "Deletes rows in table" do

    def execute
      colored_tables = Client.tables.map.with_index do
        |str, i| "#{i.to_s.rjust(3)}. #{str}".colorize(color: :light_blue)
      end
      puts "Existing tables:".colorize(:light_green), colored_tables

      tables = Client.tables
      print "Delete: ".colorize(:yellow)
      choice = STDIN.gets.chomp
      unless tables.include? choice
        puts "Unknown table"
        return
      end

      where = read_column_values(choice, "WHERE:")

      Client.delete(choice, where)
    end
  end
end

class SearchCommand < Clamp::Command

  subcommand "between", "Price between values, value in enum" do

    def execute
      print "TYPE: ".colorize(:yellow)
      type = STDIN.gets.chomp
      print "LOWER PRICE: ".colorize(:yellow)
      lower = STDIN.gets.chomp
      print "UPPER PRICE: ".colorize(:yellow)
      upper = STDIN.gets.chomp

      print_table("RESULT", Client.between(type, lower, upper))
    end
  end

  subcommand "fts", "Whole phrase, word not included" do

    def execute
    end
  end
end

def read_column_values(table, topic)
  values = {}
  puts
  puts topic.colorize(:yellow)
  Client.columns(table).each do |column|
    print "#{column}: "
    value = STDIN.gets.chomp
    values[column] = value
  end

  values.reject { |k, v| v .to_s.empty? }
end

def print_table(name, data)
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
    s = " #{str.to_s[0...30]}"
    s = (s.length >= 31) ? s.gsub(/\s\w+\s*$/, '...') : s
    s.ljust(13).colorize(color: :white, background: (i % 2 == 0) ? :light_black : :black)
  }.join("|".colorize(color: :yellow))
end

class Main < Clamp::Command
  subcommand 'seed', 'Drop schema and seed random values', SeedCommand
  subcommand 'table', 'Manipulate table data', TableCommand
  subcommand 'search', 'Search table data', SearchCommand
end

Main.run