#!/usr/bin/env ruby
#encoding=utf-8
require 'net/http'
require 'json'
require "open-uri"

require './helpers/spec_helper.rb'
require './class/user.rb'
require "./helpers/business_helper"
require "./helpers/analyze_helper.rb"


include SpecHelper
include BusinessHelper
include AnalyzeHelper


online_users_at_same_time = 10
$login_retry_times = 0
$received_msgs = 0
offset = 1
send_times = 5
DELAY = 23 # 216的时间比本机慢37秒
# DELAY = 23 # 217
# test = Time.now.to_s[11..-7]
login_sleep_seconds_base = ( online_users_at_same_time / 30 ).to_i + 2
send_sleep_seconds_base = 3

begin
  #指定同时在线的人数，每个人都随机向其他用户发送敏信指定次数

  admin_user = User.new(login_name: "100", password: "111111").login
  users_response = get "/api/v1/users", {limit: online_users_at_same_time + offset}, admin_user.header
  # log response, 0
  users_info = ( users_response[:items].map {|item| {id: item[:id], emp_code: item[:emp_code]}} )[offset..-1] # .map do |user|
#     User.loop_login({login_name: user[:emp_code], password: 111111}, ( online_users_at_same_time * rand / 30 ).to_i)
#   end

  users = []
  threads = []
  send_threads = []
  error_responses = []

  users_info.each do |user_info|
    thread = Thread.new do
      user = User.loop_login({login_name: user_info[:emp_code], password: 111111}, rand(login_sleep_seconds_base))
      users << user
    end
    threads << thread
  end

  threads.each {|t| t.join }
#   puts "登陆完毕"
  puts "登陆完毕，按enter开始发送消息"
  STDIN.gets.chomp


  user_ids = users.map {|u| u.id}
  response = users.first.direct_send_minxin(user_ids, "", {})
  conversation_id = response[:items][0][:conversation_id]

  send_pic_users = users[0..5]
  send_pic_users.each do |user|
    thread = Thread.new do

      send_times.times do |time|
        pics = Dir["./files/pic/*"]
        pic_name = pics[rand pics.size]

        response = user.send_pic_to_conversation pic_name, conversation_id
        log response, 5 if response[:errors]
        sleep send_sleep_seconds_base * rand
      end


    end
    send_threads << thread
  end

  send_threads.each {|t| t.join }
  
  #测试3：许多人一起使用工作圈并发送敏信
  #online_users_at_same_time.times do |n|
  #  thread = Thread.new do
  #    user1 = User.new(login_name: get_a_random_user(2*n)[:email], password: 111111).login
  #    user2 = User.new(login_name: get_a_random_user(2*n+1)[:email], password: 111111).login
  #
  #    # 每个人进行多少次交互操作
  #    # 10.times do |m|
  #    #   user1.direct_send_minxin user2.id, "发送消息#{m.to_s}"
  #    #   check_send user1, user2, "第#{m+1}次消息", 10 do |usr, group_id, msg|
  #    #     usr.send_messege group_id, msg
  #    #   end
  #    #   user2.direct_send_minxin user1.id, "回复消息#{m.to_s}"
  #    # end
  #    #
  #  end
  #
  #  threads << thread
  #end
  # threads.each {|t| t.join}

  puts "登陆失败次数：#{$login_retry_times}"
  puts "post次数为： #{$total_post}"
  puts "get次数为： #{$total_get}"

  puts "错误的response数：#{error_responses.size}"

  puts "post请求rainbows超时： #{$errors_count_post}"
  puts "get请求rainbows超时：#{$errors_count_get}"

  puts "post请求nginx超时： #{$time_out_count_post}"
  puts "get请求nginx超时： #{$time_out_count_get}"

  dataset = [ 
    {legend: "post_response_time", data: $post_response_time},
  ]
  title = __FILE__[0..-4]
  make_graph title, dataset, [], "#{title}.png", {x_axis_label: "time", y_axis_label: "ms"},'Line'

  rate_dataset = [ 
    {legend: "post_response_time", data: $post_response_time.rate_in(RESP_RENGES)},
  ]
  make_graph title, rate_dataset, RESP_RENGES, "#{title}_rate.png", {x_axis_label: "ms", y_axis_label: "%"}, 'Bar'
rescue Interrupt
  STDERR.print "登陆失败次数：#{$login_retry_times}\n"
  STDERR.print "post次数为： #{$total_post}\n"
  STDERR.print "get次数为： #{$total_get}\n"

  STDERR.print "错误的response数：#{error_responses.size}\n"

  STDERR.print "post请求rainbows超时： #{$errors_count_post}\n"
  STDERR.print "get请求rainbows超时：#{$errors_count_get}\n"

  STDERR.print "post请求nginx超时： #{$time_out_count_post}\n"
  STDERR.print "get请求nginx超时： #{$time_out_count_get}\n"

  dataset = [ 
    {legend: "post_response_time", data: $post_response_time},
  ]
  title = __FILE__[0..-4]
  make_graph title, dataset, [], "#{title}.png", {x_axis_label: "time", y_axis_label: "ms"},'Line'

  rate_dataset = [ 
    {legend: "post_response_time", data: $post_response_time.rate_in(RESP_RENGES)},
  ]
  make_graph title, rate_dataset, RESP_RENGES, "#{title}_rate.png", {x_axis_label: "ms", y_axis_label: "%"}, 'Bar'
end
