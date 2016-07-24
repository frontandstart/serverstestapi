require 'active_record'
require 'mysql2'
require 'yaml'

@env = ENV['RACK_ENV'] || 'development'
@config = YAML.load(File.read('./config/database.yml'))

ActiveRecord::Base.establish_connection @config[@env]

class Ip < ActiveRecord::Base
  has_many :pings
  validates_presence_of :address
  validates_presence_of :on
end

class Ping < ActiveRecord::Base
  belongs_to :ip
end
