#!/usr/bin/env ruby

require 'clamp'
require 'pry'

$LOAD_PATH << File.expand_path('./lib', __dir__)

require 'seed'

class SeedCommand < Clamp::Command
  def execute
    Seed.seed
  end
end

class Main < Clamp::Command
  subcommand 'seed', 'Drop schema and seed random values', SeedCommand
end

Main.run