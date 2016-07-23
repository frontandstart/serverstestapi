require_relative 'db'
require 'sinatra'
require "sinatra/json"
require 'thin'
require 'json'
require 'haml'
require 'eventmachine'
require 'net/ping'
require 'descriptive_statistics'

class Api < Sinatra::Base

  get '/' do
    haml :start
  end
  
  post '/ips/new' do
    hostname = Ip.new(params)
    def self.hostname_save(hostname)
      if hostname.save
        json(
          status: "success",
          id: hostname.id,
          hostname: hostname.address,
          on: hostname.on,
          stat_url: "#{request.base_url}/ips/#{hostname.id}/pings/?stat=on",
          graph_url: "#{request.base_url}/ips/#{hostname.id}/pings/?stat=on&graph=on",
        )
      else
        json( message: "Attributes for POST allowed only: address (string: hostname, ip), on (boolean: true or false)" )
      end
    end
  end
  
  put '/ips/:id/' do
    hostname = Ip.find(params[:id])
    if hostname.nil?
      json( message: "Hostname with id: #{params[:id]} dose not exist" ) 
    else
      hostname.update(params[:ip])
      hostname_save(hostname)
    end
  end
  
  delete '/ips/:id/' do
    hostname = Ip.find(params[:id])
    if hostname.nil?
      json( :message=> "Hostname with #{params[:id]} not found" )
    else
      hostname.delete
      json( :message=> "Hostname with #{params[:id]} was deleted" )
    end
  end

  get '/ips' do
    if Ip.all.blank?
      json(
        message: "We have no any hosts to ping",
        add_host_post: "#{request.base_url}/ips/new",
        alowed_params: 'address=hostname&on={true/false}'
        )
    else
      json Ip.all
    end
  end

  get '/ips/:id/' do
    ip = Ip.find(params[:id])
    if ip.nil?
      json( message: "Hostname with #{params[:id]} was deleted or not yet created" ) 
    else
      json ip
    end
  end
  

  get '/ips/:id/pings/' do
    time_from = params[:from]
    time_to = params[:to]
    time_from = Time.now.beginning_of_day.utc.iso8601 if time_from.nil?
    time_to = Time.now.utc.iso8601 if time_to.nil?
    begin
    # ... code below, i should use activerecord or another sohtgun to validate data/params but you know .. life is pain
      ip_id = params[:id].to_i
      time_from = time_from.to_time.utc.iso8601 if time_from.class != Time
      time_to = time_to.to_time.utc.iso8601 if time_to.class != Time
    rescue NoMethodError
      json( message: "Not enough or wrong param datatype, check docs" )
    rescue ArgumentError
      json( message: "Set iso8601 time format for ex: /ips/1/pings/?from=2009-10-26T04:47:09Z&to=2016-07-21T00:00:09Z" )
    end
    
    if time_to < time_from
      json( message: ":from should be less than :to" )
    else
      ip = Ip.find(params[:id])
      all_pings_records = Ping.where(:ip_id => ip_id, :created_at => time_from..time_to)

      if all_pings_records.count == 0
        json( message: "Pings dose not exist beetween this dates")

      elsif params[:compact] == 'on'
        compact_records = all_pings_records.select(:rtt, :created_at).to_a
        json compact_records

      elsif params[:graph] == 'on'
        @ip_id = ip_id
        @time_from = time_from
        @time_to = time_to
        haml :graph

      elsif params[:stat] == 'on'
        all_pings = all_pings_records.pluck(:rtt).to_a
        pings = all_pings.reject { |p| p.to_s.empty? }
        all_pings_size = all_pings.size
        pings_size = pings.size
        lost = ( ( all_pings_size.to_f.round(2) - pings_size.to_f.round(2) ) / all_pings_size.to_f.round(2) ) * 100
        lost.round(2)
        json(
          success: true,
          host_id: ip_id,
          host_address: Ip.find(ip_id).address,
          time_from: time_from,
          time_to: time_to,
          average: pings.mean,
          min: pings.min,
          max: pings.max,
          median: pings.median,
          standart_deviation: pings.standard_deviation,
          lost_pings: lost
        )
      else
        json all_pings_records
      end
    end
  end
 
  #stop EM usign curl servername/stop-em
  get '/stop-em' do
    EventMachine.stop
    json( wow: 'em stopped')
  end
    
end

EM.run do
  
  EM.add_periodic_timer(1) do
    Ip.all.each do |hostname|
      if hostname.on = true
        begin
          @send = Net::Ping::ICMP.new(host="#{hostname.address}", timeout='120')
          if @send.ping?
            ping_data = Ping.new(:ip_id => "#{hostname.id}", :rtt => "#{@send.duration}", :timeout => false, :noroute => false)
          else
            ping_data = Ping.new(:ip_id => "#{hostname.id}", :rtt => "", :timeout => true, :noroute => false)
          end
        rescue Errno::EHOSTUNREACH
          ping_data = Ping.new(:ip_id => "#{hostname.id}", :rtt => "", :timeout => false, :noroute => true)
        end
      else
        # Do nothing when hostname disable
      end
      ping_data.save!        
    end
  end

  #if you try to get post my api so hard its probably help sometime
  EM.add_periodic_timer(22) do
    ActiveRecord::Base.clear_active_connections!
  end

  Api.run!
end

# In sart of this task I start write pure SQL for db, and then think if I wantto change db structure..
# Than start little bit research ICMP protocol and decide use core NET::PING::ICMP
# but soon i found this gem https://github.com/zzip/icmp4em/ and this code will be more pure and it will be easy way.
# So task interestind and not limit in time/functional border. And in one time i think - just write working code.