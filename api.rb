require 'sinatra'
require 'mysql2'
require 'eventmachine'
require 'parallel'
require 'active_record'
require 'json'
require 'net/ping'
require 'haml'

ActiveRecord::Base.establish_connection(
  adapter: "mysql2",
  encoding: "utf8",
  database: "sintest",
  username: "4au",
  password: "xyz88"
)

class Ip < ActiveRecord::Base
  has_many :pings
  validates_presence_of :address
  validates_presence_of :on
end

class Ping < ActiveRecord::Base
  belongs_to :ip
end

def run(opts)
  EM.run do
    Parallel.each(Ip.where(:on => true), in_threads: 11) do |host|
      EM.add_periodic_timer(1) do
        File.open("/Users/4au/servers-api/log/#{host.id}_#{host.address}.log", 'w+') do |f|
          f.puts "EventMachine test action at #{Time.now} ping on #{host.address}"
          @send = Net::Ping::ICMP.new("#{host.address}")
          if @send.ping?
            f.puts "ID: #{host.id}, address: #{host.address} - resolve in #{@send.duration}"
          else
            f.puts "id: #{host.id}, address: #{host.address} not resolve"
          end
        end
      end
    end
  end
end  

class Apiapp < Sinatra::Base
  get '/' do
    haml :start
  end

  post '/ips/?' do
    hostname = Ip.new(params)
    if hostname.save
      [201, { :message=> "Hostname #{params[:address]} add"}.to_json ]
    else
      [422, { :message=> "Attributes for POST allowed only: address (string: hostname, ip), on (boolean: true or false)"}.to_json ]
    end
  end

  put '/ips/:id' do
    hostname = Ip.find(params[:id])
    return status 404 if widget.nil?
    hostname.update(params[:ip])
    hostname.save
    status 202
  end

  delete '/ips/:id' do
    hostname = Ip.find(params[:id])
    return status 404 if hostname.nil?
    hostname.delete
    status 202
  end

  get '/ips/:id' do
    ip = Ip.find(params[:id])
    return [ 404, { :message => "Hostname with #{params[:id]} was deleted or not yet created"}.to_json ] if ip.nil?
    ip.to_json
  end

  get '/ips' do
    p Ip.all.to_json
  end
  
end

run app: Apiapp.new
