namespace :db do
  desc "Truncate all tables"
  task :truncate => :environment do
    conn = ActiveRecord::Base.connection
    tables = conn.execute("select tablename from pg_tables").map { |r| r[0] }
    tables.each { |t| conn.execute("TRUNCATE #{t}") }
  end
end

