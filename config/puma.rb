app_folder = "#{Dir.getwd}"
bind "unix://#{app_folder}/tmp/sockets/puma"
pidfile "#{app_folder}/tmp/pids/puma"
state_path "#{app_folder}/tmp/state_puma"
activate_control_app "unix://#{app_folder}/tmp/pids/pumactl.sock"
rackup "#{app_folder}/config.ru"
threads 8, 32
workers 3
preload_app!
daemonize true