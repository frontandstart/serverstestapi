# DB migrations
require_relative 'db'
namespace :db do
  task :default => :migrate
  task :migrate do
    ActiveRecord::Migrator.migrate('db/migrate', ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
  end  
end
