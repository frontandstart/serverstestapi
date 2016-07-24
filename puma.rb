#!/usr/bin/env puma
activate_control_app "tcp://127.0.0.1:9293"
bind "unix:///home/cloud-user/api/tmp/sockets/puma.sock"
pidfile "/home/cloud-user/api/tmp/pids/puma.pid"
rackup "/home/cloud-user/api/config.ru"
state_path "/home/cloud-user/api/tmp/pids/puma.state"
environment 'production'
workers 2
threads 4, 16
daemonize true