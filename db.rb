require 'active_record'
require 'mysql2'
require 'yaml'

@environment = ENV['RACK_ENV'] || 'development'
@dbconfig = YAML.load(File.read('./db/database.yml'))
ActiveRecord::Base.establish_connection @dbconfig[@environment]

class Ip < ActiveRecord::Base
  has_many :pings
  validates_presence_of :address
  validates_presence_of :on
end

class Ping < ActiveRecord::Base
  belongs_to :ip
end
