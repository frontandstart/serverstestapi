#!/usr/bin/env puma
directory '/home/cloud-user/api'
environment 'production'
pidfile '/home/cloud-user/api/tmp/pids/puma.pid'
threads 0, 16
bind 'unix:///home/cloud-user/api/tmp/sockets/puma.sock'
workers 2