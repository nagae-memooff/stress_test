#!/usr/bin/env ruby
#encoding=utf-8
host = "localhost"
memcached_port = 11211
redis_port = 6379
sleep_seconds = 1

loop do
  memcached_info = `echo "stats" |nc #{host} #{memcached_port} -q5`
  memcached_info =~ /STAT get_hits ([0-9]+)/
  get_hits = $1.to_i
  memcached_info =~ /STAT get_misses ([0-9]+)/
  get_misses = $1.to_i
  memcached_info =~ /STAT cmd_get ([0-9]+)/
  total_get = $1.to_i

  redis_info = `redis-cli -h #{host} -p #{redis_port} info`
  redis_info =~ /used_memory:([0-9]+)/
  used_memory = $1.to_i
  redis_info =~ /used_memory_human:([0-9]+\.[0-9]+[GMK])/
  used_memory_human = $1
  redis_info =~ /used_memory_peak_human:([0-9]+\.[0-9]+[GMK])/
  used_memory_peak_human = $1
  redis_info =~ /mem_fragmentation_ratio:([0-9]+\.[0-9]+)/
  mem_fragmentation_ratio = $1.to_f
  redis_status =
    if mem_fragmentation_ratio < 1.0
      "有内存数据被换入交换分区，会影响性能"
    elsif mem_fragmentation_ratio >= 3.0 && used_memory > 10000000
      "内存碎片较多"
    else
      "状态良好"
    end
  redis_info =~ /connected_clients:([0-9]+)/
  connected_clients = $1
  redis_info =~ /blocked_clients:([0-9]+)/
  blocked_clients = $1

  nginx_connects_established = `netstat -n | grep -e "218:8018 .* ESTABLISHED" | wc -l`
  nginx_connects_time_wait = `netstat -n | grep -e "218:8018 .* TIME_WAIT" | wc -l`

  puts "memcached命中率为： #{get_hits * 100 / total_get } %"
  puts "redis占用内存： #{used_memory_human}"
  puts "redis内存碎片比例： #{mem_fragmentation_ratio} #{redis_status}"
  puts "redis占用内存峰值：#{used_memory_peak_human}"
  puts "redis已连接客户端数： #{connected_clients}"
  puts "redis阻塞中客户端数： #{blocked_clients}"
  puts "nginx ESTABLISHED数：#{nginx_connects_established}"
  puts "nginx TIME_WAIT数：#{nginx_connects_time_wait}"

  puts "=========#{Time.now}=============="
  sleep sleep_seconds
end
