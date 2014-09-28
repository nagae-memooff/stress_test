#!/usr/bin/env ruby
#encoding=utf-8
log_path = ARGV[0] || "/home/ewhine/system_info.log"
sleep_seconds = ARGV[1].to_i || 5

loop do
  cmd = 'ps axu|egrep -e "sidekiq" -e "rainbow" -e "redis"  -e "3306" -e "nginx" -e "mqtt3d"|grep -v egrep| grep -v tail|grep -v ruby | grep -v logger|grep -v bash >> ' + log_path
  str = `#{cmd}`
  sleep sleep_seconds
end
