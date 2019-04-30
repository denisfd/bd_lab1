require 'pg'
require 'colorize'

module Client
  def self.conn
    @conn ||= PG.connect(
      dbname: 'lab1',
      user: 'postgres',
      password: 's3cr3t',
      host: '0.0.0.0',
      port: '5432',
    )
  end

  def self.prepare
    Client.colorized(:light_blue) do |c|
      puts "-> DROPPING TABLES".colorize(:red)

      c.exec "DROP TABLE IF EXISTS activities"
      c.exec "DROP TYPE IF EXISTS intensity"
      c.exec "CREATE TYPE intensity
        AS ENUM ('cardio', 'bodyweight', 'freeweight')"
      c.exec "DROP TABLE IF EXISTS trainers"
      c.exec "DROP TABLE IF EXISTS clients"

      puts "-> CREATING TABLES".colorize(:green)
      c.exec "CREATE TABLE activities
        (id VARCHAR(30) PRIMARY KEY, type intensity, description TEXT)"
      c.exec "CREATE TABLE trainers
        (id SERIAL PRIMARY KEY, name VARCHAR(20), surname VARCHAR(20), activity_id VARCHAR(30), price INTEGER)"
      c.exec "CREATE TABLE clients
      (id SERIAL PRIMARY KEY, name VARCHAR(20), surname VARCHAR(20), trainer_id INTEGER, bio TEXT)"
      puts "<- TABLES CREATED\n".colorize(:green)
    end
  end

  def self.colorized(color)
    old = conn.set_notice_processor { |m| print m.colorize(color) }

    yield conn

    conn.set_notice_processor &old
  end

  def self.all(table)
    res = conn.exec("SELECT * FROM #{table.to_s}")

    res.collect { |row| row.inject({}) { |h, (k, v)| h[k.to_sym] = v; h } }
  end

  def self.insert(table, params)
    columns = params.keys
    values = columns.collect { |c| params[c] }
    Client.conn.exec "INSERT INTO #{table.to_s}
      (#{columns.map { |c| c.to_s }.join(", ")})
      VALUES (#{values.map { |v| "'#{v.to_s}'" }.join(", ")})"
  end

  def self.where(params)
    return if params.length.zero?

    "WHERE #{params.map { |k, v| "#{k} = '#{v}'" }.join(", ")}"
  end

  def self.update(table, s, w)
    return if s.length.zero?

    conn.exec "UPDATE #{table}
      SET #{s.map { |k, v| "#{k} = '#{v}'" }.join(", ")}
      #{where(w)}"
  end

  def self.delete(table, w)
    conn.exec "DELETE FROM #{table} #{where(w)}"
  end

  def self.tables
    conn.exec("SELECT table_name
      FROM information_schema.tables
      WHERE table_type='BASE TABLE'
      AND table_schema='public';").values.flatten
  end

  def self.columns(table)
    conn.exec("SELECT column_name FROM information_schema.columns
      WHERE table_name='#{table.to_s}'").values.flatten
  end

  def self.between(type, lower, upper)
    conn.exec("SELECT t.name, t.surname, t.activity_id, t.price
      FROM trainers AS t, activities AS a
      WHERE t.activity_id = a.id
      AND a.type = '#{type}'
      AND t.price BETWEEN #{lower} AND #{upper}
      ORDER BY t.price ASC").collect { |r| r }
  end
end