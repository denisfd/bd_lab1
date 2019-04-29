#!/usr/bin/env ruby

require 'clamp'
require 'pry'

class ListData < Clamp::Command
  def execute
    puts 'Hello'
  end
end

class Main < Clamp::Command
  subcommand 'tables', 'List data from table', ListData
end

Main.run