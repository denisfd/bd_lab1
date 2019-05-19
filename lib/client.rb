require 'sequel'
require 'colorize'

module Client
  def self.conn
    @conn ||= Sequel.connect('postgres://postgres:s3cr3t@0.0.0.0:5432/lab1')
  end

  def self.prepare
    conn.tap do |c|
      puts "-> DROPPING TABLES".colorize(:red)

      c.drop_table?(:activities, :trainers, :clients, cascade: true)

      c.create_table :activities do
        String :id, primary_key: true
        String :type
        String :description, text: true
      end

      c.create_table :trainers do
        primary_key :id
        String :name
        String :surname
        foreign_key :activity_id, :activities, type: 'text'
        Integer :price
      end

      c.create_table :clients do
        primary_key :id
        String :name
        String :surname
        foreign_key :trainer_id, :trainers
        String :bio, text: true
      end
    end

    trigger
    procedure
  end

  def self.all(table)
    conn[table].all
  end

  def self.insert(table, params)
    conn[table].insert(params)
  end

  def self.update(table, s, w)
    return if s.length.zero?

    conn[table].where(w).update(s)
  end

  def self.delete(table, w)
    conn[table].where(w).delete
  end

  def self.tables
    conn.tables
  end

  def self.columns(table)
    conn[table].columns
  end

  def self.between(type, lower, upper)
    query = "SELECT t.name, t.surname, t.activity_id, t.price
      FROM trainers AS t, activities AS a
      WHERE t.activity_id = a.id
      AND a.type = '#{type}'
      AND t.price BETWEEN #{lower} AND #{upper}
      ORDER BY t.price ASC"

    conn[query].all
  end

  def self.fts(phrase, exclude)
    query =  "CREATE OR REPLACE FUNCTION make_tsvector(description TEXT)
        RETURNS tsvector AS $$
      BEGIN
        RETURN (setweight(to_tsvector('english', description),'A'));
      END
      $$ LANGUAGE 'plpgsql' IMMUTABLE;

      CREATE INDEX IF NOT EXISTS idx_fts_activities ON activities
        USING gin(make_tsvector(description));

      SELECT id, ts_headline(description, q) AS description FROM activities,
      to_tsquery('#{phrase.split.join(" <-> ")} & !#{exclude.split[0]}') AS q
        WHERE to_tsvector(description) @@ q;"

    conn[query].all
  end

  def self.trigger
    conn << "CREATE OR REPLACE FUNCTION price_positive()
      RETURNS trigger AS
      $BODY$
        BEGIN
          IF NEW.price <= 0 THEN
            RETURN OLD;
          END IF;
          RETURN NEW;
        END;
      $BODY$
      LANGUAGE plpgsql VOLATILE;"

    conn << "CREATE TRIGGER validate_price
      BEFORE UPDATE
      ON trainers
      FOR EACH ROW
      EXECUTE PROCEDURE price_positive();"
  end

  def self.procedure
    conn << "CREATE OR REPLACE PROCEDURE cheaperTrainer(INT)
    LANGUAGE plpgsql
    AS $$
    BEGIN
        UPDATE clients
        SET trainer_id = (SELECT id FROM trainers ORDER BY price ASC LIMIT 1)
        WHERE id = $1;

        COMMIT;
    END;
    $$;"
  end
end
