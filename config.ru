require "sinatra"
configure { set :server, :puma }
require './ServersApi'
run ServersApi