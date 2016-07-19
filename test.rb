require 'sinatra'
require 'eventmachine'
require 'json'
require 'net/ping'
require 'haml'
#require 'facets'
require_relative 'db'


get '/ips/:id/pings/' do
  ip_id = params[:id].to_s
  time_from = params[:from]
  time_to = params[:to]
  # check valid time format & convert to iso8601
  begin
    time_from = time_from.to_time.iso8601
    time_to = time_to.to_time.iso8601
  rescue ArgumentError
    return [ 401, { :message => "Set time interval in iso8601 format for ex: /ips/1/?from=2009-10-26T04:47:09Z?to=2016-07-19T00:00:09Z"}.to_json ]
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
      
      return [200,{
        :all_pings => all_pings.count,
        :exist_pings => pings.count
      }.to_json ]
      
      
    end
  
  else
    return [ 401, { :message => "Time :from should be less than :to"}.to_json ]
  end
end


get '/ips' do
  all_pings = Ping.where(:ip_id => ip_id, :created_at => time_from..time_to).pluck(:rtt)
  all_pings.to_json
  all_pings.each do |ping|
    puts ping
  end

end
