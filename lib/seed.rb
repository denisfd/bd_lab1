require 'client'
require 'fabric'

module Seed
  def self.seed
    Client.prepare

    activities
    trainers
    clients
  end

  def self.clients
    puts ".. Seeding Clients".colorize(:light_green)
    trainers = Client.all(:trainers)
    rand(30...50).times do
      c = {
        name: Fabric.name,
        surname: Fabric.surname,
        trainer_id: trainers.sample[:id],
        bio: Fabric.bio,
      }
      print "->".colorize(:yellow),
      " Seeding".colorize(:green),
      " #{c[:name]} #{c[:surname]}\n".colorize(:light_blue)
      Client.insert(:clients, c)
    end
    puts "<- Seeded Clients\n".colorize(:light_green)
  end


  def self.trainers
    puts ".. Seeding Trainers".colorize(:light_green)
    Client.all(:activities).each do |act|
      rand(1...5).times do
        t = {
          name: Fabric.name,
          surname: Fabric.surname,
          activity_id: act[:id],
          price: rand(100...500),
        }
        print "->".colorize(:yellow),
        " Seeding".colorize(:green),
        " #{t[:name]} #{t[:surname]}: #{t[:activity_id]} #{t[:price]}$\n".colorize(:light_blue)
        Client.insert(:trainers, t)
      end
    end
    puts "<- Seeded Trainers\n".colorize(:light_green)
  end

  def self.activities
    puts ".. Seeding Activities".colorize(:light_green)
    [
      { id: "running", type: "cardio", description: "Running is a greate exercise for summer. Helps to keep in fit." },
      { id: "skiing", type: "cardio", description: "Skiing is great activity for winter." },
      { id: "calisthenics", type: "bodyweight", description: "Build strength with no additional equipment." },
      { id: "heavylifting", type: "freeweight", description: "Become a Hulk, but no so green." },
      { id: "fitness", type: "bodyweight", description: "Keep in fit with interesting exercises." },
      { id: "swimming", type: "bodyweight", description: "Keep in fit and develop your strength." },
    ].each do |act|
      print "->".colorize(:yellow),
        " Seeding".colorize(:green),
        " #{act[:id]}:#{act[:type]}\n".colorize(:light_blue)
      Client.insert(:activities, act)
    end
    puts "<- Seeded Activities\n".colorize(:light_green)
  end
end