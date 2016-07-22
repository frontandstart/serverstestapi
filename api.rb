require_relative 'db'
require 'sinatra'
require "sinatra/reloader"
require 'thin'
require 'json'
require 'haml'
require 'eventmachine'
require 'net/ping'


#this magic gem just for calculate math statistic.
require 'descriptive_statistics'


class Api < Sinatra::Base
  register Sinatra::Reloader

  get '/' do
    haml :start
  end
  
  post '/ips/new' do
    hostname = Ip.new(params)
    def self.hostname_save(hostname)
      if hostname.save
        return [ 201, {
          status: "success",
          id: hostname.id,
          hostname: hostname.address,
          on: hostname.on,
          stat_url: "#{request.base_url}/ips/#{hostname.id}/pings/?stat=on",
          graph_url: "#{request.base_url}/ips/#{hostname.id}/pings/?stat=on&graph=on",
          }.to_json 
        ]
      else
        [422, { :message => "Attributes for POST allowed only: address (string: hostname, ip), on (boolean: true or false)"}.to_json ]
      end
    end
  end
  
  put '/ips/:id/' do
    hostname = Ip.find(params[:id])
    return [404, { :message=> "Hostname with id: #{params[:id]} dose not exist ]"}.to_json ] if hostname.nil?
    hostname.update(params[:ip])
    hostname_save(hostname)
  end
  
  delete '/ips/:id/' do
    hostname = Ip.find(params[:id])
    return status 404 if hostname.nil?
    hostname.delete
    status 202
  end

  get '/ips' do
    if Ip.all.blank?
      return [ 200, {
        message: "We have no any hosts to ping",
        add_host_post: "#{request.base_url}/ips/new",
        alowed_params: 'address=hostname&on={true/false}'
        }.to_json
      ]
    else
      return [ 200, Ip.all.each.to_json ]
    end
  end

  get '/ips/:id/' do
    ip = Ip.find(params[:id])
    return [ 404, { :message => "Hostname with #{params[:id]} was deleted or not yet created"}.to_json ] if ip.nil?
    ip.to_json
  end
  

  get '/ips/:id/pings/' do
    time_from = params[:from]
    time_to = params[:to]
    begin
    # ... code below, i should use activerecord or another sohtgun to validate data/params but you know .. life is pain
      ip_id = params[:id].to_i
      time_from = time_from.to_time.utc.iso8601
      time_to = time_to.to_time.utc.iso8601
    rescue NoMethodError
      return [ 401, { :message => "Not enough or wrong param datatype, check docs" }.to_json ]
    rescue ArgumentError
      return [ 401, { :message => "Set iso8601 time format for ex: /ips/1/pings/?from=2009-10-26T04:47:09Z&to=2016-07-21T00:00:09Z"}.to_json ]
    end
    if time_to < time_from
      return [ 401, { :message => ":from should be less than :to"}.to_json ]
    #elsif params[:graph] == 'on'
    #  @ip_id = ip_id
    #  @time_from = time_from
    #  @time_to = time_to
    #  haml :graph
    else
      ip = Ip.find(params[:id])
      all_pings = Ping.where(:ip_id => ip_id, :created_at => time_from..time_to).pluck(:rtt)
      pings = all_pings.reject(&:blank?)
      all_pings_size = all_pings.size
      pings_size = pings.size
      if all_pings_size == 0
        return [ 401, { :message => "Pings dose not exist beetween this dates"}.to_json ]  
      elsif params[:stat] == 'on'
        return [
          200, {
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
            lost_percentage: ( ( all_pings_size - pings_size ) / all_pings_size ) * 100
          }.to_json
        ]
      else
        all_time_pings = Ping.where(:ip_id => ip_id, :created_at => time_from..time_to).pluck(:created_at ,:rtt)
        return [ 200, all_time_pings.to_json  ]
      end
    end
  end
  
  
  #stop EM usign curl servername/stop-em
  get '/stop-em' do
    EventMachine.stop
  end
    
end

EM.run do
  
  EM.add_periodic_timer(1) do
    Ip.all.each do |hostname|
      if hostname.on = true
        begin
          @send = Net::Ping::ICMP.new(host="#{hostname.address}", timeout='120')
          if @send.ping?
            # if success
            ping_data = Ping.new(:ip_id => "#{hostname.id}", :rtt => "#{@send.duration}", :timeout => false, :noroute => false)
          else
            # if timeout > timeout param @send
            ping_data = Ping.new(:ip_id => "#{hostname.id}", :timeout => true, :noroute => false)
          end
        rescue Errno::EHOSTUNREACH
          # if no routes
          ping_data = Ping.new(:ip_id => "#{hostname.id}", :timeout => false, :noroute => true)
        end
        # save to DB
      else
          # do nothing for disable hostnames
      end
      ping_data.save!        
    end
  end

  #if you try to get post my api so hard its probably help sometime
  EM.add_periodic_timer(15) do
    ActiveRecord::Base.clear_active_connections!
  end

  Api.run!
end

# In sart of this task I start write pure SQL for db, and then think if I wantto change db structure.. Than start little bit research ICMP protocol and decide use core NET::PING::ICMP but soon i found this gem https://github.com/zzip/icmp4em/ and this code will be more pure and it will be easy way. So task interestind and not limit in time/functional border. And in one time i think just write working code.