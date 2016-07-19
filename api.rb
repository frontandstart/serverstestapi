require 'sinatra'
require 'eventmachine'
require 'json'
require 'net/ping'
require 'haml'
require 'facets'
require_relative 'db'


EM.run do

  EM.add_periodic_timer(1) do
    Ip.all.each do |hostname|
      if hostname.on = true
        begin
          @send = Net::Ping::ICMP.new(host="#{hostname.address}", timeout='120')
          if @send.ping?
            # if success
            db_ping = Ping.new(:ip_id => "#{hostname.id}", :rtt => "#{@send.duration}", :timeout => false, :noroute => false)
          else
            # if timeout > 2 min
            db_ping = Ping.new(:ip_id => "#{hostname.id}", :timeout => true, :noroute => false)
          end
        rescue Errno::EHOSTUNREACH
          # if no routes
          db_ping = Ping.new(:ip_id => "#{hostname.id}", :timeout => false, :noroute => true)
        end
        # save to DB
      else
          # do nothing for disable hostnames
      end
      db_ping.save!        
    end
  end
  
  class Api < Sinatra::Base


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

    put '/ips/:id/' do
      hostname = Ip.find(params[:id])
      return [404, { :message=> "Hostname with id: #{params[:id]} dose not exist
      ]"}.to_json ]if hostname.nil?
      hostname.update(params[:ip])
      hostname.save
      status 202
    end

    delete '/ips/:id/' do
      hostname = Ip.find(params[:id])
      return status 404 if hostname.nil?
      hostname.delete
      status 202
    end

    get '/ips/:id/' do
      ip = Ip.find(params[:id])
      return [ 404, { :message => "Hostname with #{params[:id]} was deleted or not yet created"}.to_json ] if ip.nil?
      ip.to_json
    end

    get '/ips/:id/pings/' do
      ip_id = params[:id].to_s
      time_from = params[:from]
      time_to = params[:to]
      # check valid time format & convert to iso8601
      begin
        time_from = time_from.to_time.iso8601
        time_to = time_to.to_time.iso8601
      rescue ArgumentError
        return [ 401, { :message => "Set iso8601 time format for ex: /ips/1/?from=2009-10-26T04:47:09Z?to=2016-07-19T00:00:09Z"}.to_json ]
      end
      
      if  time_to > time_from
        # do all request processing here
        ip = Ip.find(params[:id])
        all_pings = Ping.where(:ip_id => ip_id, :created_at => time_from..time_to).pluck(:rtt)
        pings = all_pings.reject!(&:empty?)

        if all_pings.nil?
          return [ 401, { :message => "Pings dose not exist beetween this dates"}.to_json ]  
        else
          # percentage of success pings
          all_pings_size = all_pings.size
          lost_pings = ( ( all_pings_size - pings.size ) / all_pings_size ) * 100
          
          return [200, {
            :host => "#{Ip.find(ip_id).address}",
            :time_from => "#{time_from}",
            :time_to => "#{time_to}",
            :maximum => "#{pings.max}",
            :minimum => "#{pings.min}",
            #:median => pings.median,
            #:mean => pings.mean,
            # Standard deviation from Math module
            #:standart_deviation => pings.pstd,
            :lost => "#{lost_pings} %"
          }.to_json ]
          
          
        end
      
      else
        return [ 401, { :message => ":from should be less than :to"}.to_json ]
      end
    end
  
    get '/ips/' do
      p Ip.all.to_json
    end
    
    def median(array, already_sorted=false)
  	  return nil if array.empty?
  	  array = array.sort unless already_sorted
  	  m_pos = array.size / 2
  	  return array.size % 2 == 1 ? array[m_pos] : mean(array[m_pos-1..m_pos])
    end
  end

  Api.run!({:port => 3003})

end
