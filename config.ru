require "sinatra"
require './apiping'
configure { set :server, :puma }
run! apiping