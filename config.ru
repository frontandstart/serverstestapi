require "sinatra"
require './ServersApi'
configure { set :server, :puma }
run ServersApi