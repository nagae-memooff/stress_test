#!/usr/bin/env ruby
#encoding=utf-8
require 'net/http'
require 'json'
require "open-uri"

require './helpers/spec_helper.rb'
require './class/user.rb'
require "./helpers/analyze_helper.rb"


include SpecHelper
include AnalyzeHelper


online_users_at_same_time = 60
receive_limit = 10000
$login_retry_times = 0
$received_msgs = 0
$start_at = nil
$end_at = nil
offset = 2

begin
  admin_user = User.new(login_name: "100", password: "111111").login
  response = get "/api/v1/users", {limit: online_users_at_same_time + offset}, admin_user.header

  msg_bodys = []
  times = []
  # log response, 0
  user_ids = ( response[:items].map {|item| {id: item[:id], emp_code: item[:emp_code]}} )[offset..-1]

  threads = []
  online_users_at_same_time.times do |n|
    thread = Thread.new do
      user1 = User.loop_login({login_name: user_ids[n][:emp_code], password: 111111}, ( online_users_at_same_time * rand / 30 ).to_i)
      puts "用户#{user1.id}登陆完毕"
#     user1.receive_mqtt
      begin
        user1.receive_mqtt do |topic, msg|

          msg = JSON.parse(msg, symbolize_names: true)
          if msg[:data].has_key? :body
            msg_a = msg[:data][:body].split(",")
          
            send_time = msg_a[1].to_i
            if send_time != 0
              $received_msgs += 1
              puts "开始于：#{$start_at = Time.now }" if $received_msgs == 1
              received_msgs_tmp = $received_msgs
              puts "于#{Time.now.to_s}收到#{received_msgs_tmp}条消息" if received_msgs_tmp % 200 == 0
              received_time = Time.now.to_i
              delay = received_time - send_time
              delay = 0 if delay < 0
              puts "send #{send_time} rec #{received_time} delay #{delay}"
              times << delay
              #         puts delay
              msg_bodys << msg_a.first
            end
            #         puts msg_body
           # raise Interrupt if $received_msgs > receive_limit
          end
        end
 #     rescue MQTT::ProtocolException
  #      puts "捕获到MQTT::ProtocolException"
      rescue => e
        puts e.inspect
      end
    end
    threads << thread
  end

  threads.each {|t| t.join}

rescue Interrupt
  $end_at = Time.now
  if $received_msgs > 0
    STDERR.print "收到的消息总数：#{$received_msgs}\n"
    STDERR.print "开始于：#{$start_at}\n"
    STDERR.print "结束于：#{$end_at}\n"
    STDERR.print "推送速度：#{$received_msgs / ($end_at - $start_at)}条/秒\n"
    # 检查重复相关逻辑
    if msg_bodys.uniq.size == $received_msgs
      STDERR.print "收到的消息没有重复\n"
    else
      STDERR.print "收到的消息出现#{$received_msgs - msg_bodys.uniq.size}条重复\n"
    end
  
    # 计算平均响应时间
    times.rate_graph MQTT_RECEIVE_RANGES, "message delay times(s)", {x_axis_label: "ms", y_axis_label: "%"}, "mqtt_receive.png", 'Bar'
    
    
  else
    STDERR.print "结束"
  end

end
