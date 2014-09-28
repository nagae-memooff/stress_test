#!/usr/bin/env ruby
#encoding=utf-8

host1 = "192.168.100.236"
host2 = "192.168.100.217"

from = ARGV[0] || 1
to = ARGV[1] || 100

puts from
puts to

thread_region = (from..to)
threads = []
test_times = 30
error_array = []

thread_region.each do |n|
  thread = Thread.new do
    test_times.times do |m|
      cmd1 = "redis-cli -h #{host1} set test_key_#{n} #{m}"
      cmd2 = "redis-cli -h #{host2} get test_key_#{n}"

      result1 = `#{cmd1}`
      result2 = `#{cmd2}`

      begin
        error_array << {key: "test_key_#{n}", expect: m, response: result2} if result2.to_i != m.to_i
        puts "设置test_key_#{n}为#{m}时,接收到#{result1}，但是期望为OK" if result1 != "OK\n"
      rescue StandardError
        puts "在第#{n}线程,接收到#{result2}，但是期望为#{m}"
      end
    end
  end

  threads << thread
end

threads.each {|t| t.join}

puts error_array
