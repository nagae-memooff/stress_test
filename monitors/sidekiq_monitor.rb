#!/usr/bin/env ruby
#encoding=utf-8
loop do
  cmd = "ps ax|grep sidekiq|grep ewhine_NB|grep -v sh"
  puts `#{cmd}\n=================#{Time.now}=====================`
  sleep 1
end
