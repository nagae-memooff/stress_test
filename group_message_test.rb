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


online_users_at_same_time = 40
$login_retry_times = 0
$received_msgs = 0
offset = 10
send_times = 10000
DELAY = 0 # 216的时间比本机慢37秒
# DELAY = 23 # 217
# test = Time.now.to_s[11..-7]
login_sleep_seconds_base = ( online_users_at_same_time / 30 ).to_i + 2
send_sleep_seconds_base = 2
receivers = (25..35).to_a
conv_ids = []
ADMIN = {login_name: "admin@ee.com", password: "111111"}

begin
  #指定同时在线的人数，每个人都随机向其他用户发送敏信指定次数

  admin_user = User.new(ADMIN).login
  users_response = get "/api/v1/users", {limit: online_users_at_same_time + offset}, admin_user.header
#   log users_response, 5
  users_info = ( users_response[:items].map {|item| {id: item[:id], emp_code: item[:emp_code], login_name: item[:login_name]} } )[offset..-1] # .map do |user|

  users = []
  threads = []
  send_threads = []
  error_responses = []

  users_info.each do |user_info|
    thread = Thread.new do
      users << User.loop_login({login_name: user_info[:login_name], password: 111111}, login_sleep_seconds_base * rand )
    end
    threads << thread
  end

  threads.each {|t| t.join }
#   puts "登陆完毕"
  puts "登陆完毕，按enter开始发送消息"
  STDIN.gets.chomp


  users.each do |user|
    thread = Thread.new do
      # 第一次直接用用户id发送
      user2_id = []
      receivers.get_rand.times {|time| user2_id << users.get_rand.id }
      (user2_id - [user.id]).uniq!
      msg_text = "#{user.id}, #{Time.now.to_i + DELAY}"
      response = user.direct_send_minxin user2_id, msg_text
#       log response, 5
      log response, 5 if ( response.nil? || response[:items].nil? )

      conversation_id = response[:items].first[:conversation_id]
      conv_ids << conversation_id
      sleep send_sleep_seconds_base * rand

      # 有过一次会话以后，通过会话id发送
      (send_times - 1).times do |time|
        msg_text = "#{2 * (time + 1) * online_users_at_same_time + user.id}, #{Time.now.to_i + DELAY }"
        r = user.send_minxin_by_conversation_id conversation_id, msg_text
        log send_resp, 5 if r[:errors]
        sleep send_sleep_seconds_base * rand
      end

    end
    send_threads << thread
  end

  send_threads.each {|t| t.join }

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
#   post_response_time_png = "group_msg_test_post_response_time.png"
#   $post_response_time.graph RESP_RENGES, "post response time(ms)", {}, post_response_time_png
#   puts "post响应时间图片生成至#{post_response_time_png}"

#   get_response_time_png = "group_msg_test_get_response_time.png"
#   $get_response_time.graph RESP_RENGES, "get response time(ms)", {}, get_response_time_png
#   puts "get响应时间图片生成至#{get_response_time_png}"
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
  if conv_ids.uniq.count == conv_ids.count
    puts "没有重复的conv_id"
  else
    puts "出现重复的conv_id: #{(conv_ids - conv_ids.uniq).inspect}"
  end

#   post_response_time_png = "group_msg_test_post_response_time.png"
#   $post_response_time.graph RESP_RENGES, "post response time(ms)", {}, post_response_time_png
#   puts "post响应时间图片生成至#{post_response_time_png}"

#   get_response_time_png = "group_msg_test_get_response_time.png"
#   $get_response_time.graph RESP_RENGES, "get response time(ms)", {}, get_response_time_png
#   puts "get响应时间图片生成至#{get_response_time_png}"
end
