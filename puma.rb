#!/usr/bin/env puma
directory '/home/cloud-user/api'
environment 'production'
pidfile '/home/cloud-user/api/tmp/pids/puma.pid'
threads 4, 16
bind 'unix:///home/cloud-user/api/tmp/sockets/puma.sock'
workers 2



activate_control_app "tcp://127.0.0.1:9293"
bind "unix:///tmp/puma.pumatra.sock"
pidfile "/home/cloud-user/api/tmp/pids/puma.pid"
rackup "#{root}/config.ru"
state_path "#{root}/tmp/pids/puma.state"