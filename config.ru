require 'sinatra'
require_relative './api'
configure { set :server, :puma }
run Api