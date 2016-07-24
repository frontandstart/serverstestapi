#!/usr/bin/env ruby
require 'eventmachine'
require 'thin'
require 'net/ping'
require './db'
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
end