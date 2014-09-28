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


online_users_at_same_time = 50
$login_retry_times = 0
$received_msgs = 0
offset = 10
DELAY = 0 # 216的时间比本机慢37秒
# DELAY = 23 # 217
# test = Time.now.to_s[11..-7]
login_sleep_seconds_base = ( online_users_at_same_time / 30 ).to_i + 2

begin
  #指定同时在线的人数，每个人都随机向其他用户发送敏信指定次数

  admin_user = User.new(login_name: "100", password: "111111").login
  users_response = get "/api/v1/users", {limit: online_users_at_same_time + offset}, admin_user.header
#   log users_response, 5
  users_info = ( users_response[:items].map {|item| {id: item[:id], emp_code: item[:emp_code]}} )[offset..-1] # .map do |user|

  users = []
  threads = []
  error_responses = []

  users_info.each do |user_info|
    thread = Thread.new do
      loop do
        users << User.loop_login({login_name: user_info[:emp_code], password: 111111}, login_sleep_seconds_base * rand )
      end
    end
    threads << thread
  end

  threads.each {|t| t.join }
#   puts "登陆完毕"
  puts "登陆完毕，按enter开始发送消息"
  STDIN.gets.chomp




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
    {legend: "get_response_time", data: $get_response_time }
  ]
  title = __FILE__[0..-4]
  make_graph title, dataset, [], "#{title}.png", {x_axis_label: "time", y_axis_label: "ms"},'Line'

  rate_dataset = [ 
    {legend: "post_response_time", data: $post_response_time.rate_in(RESP_RENGES)},
    {legend: "get_response_time", data: $get_response_time.rate_in(RESP_RENGES) }
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
    {legend: "get_response_time", data: $get_response_time }
  ]
  title = __FILE__[0..-4]
  make_graph title, dataset, [], "#{title}.png", {x_axis_label: "time", y_axis_label: "ms"},'Line'

  rate_dataset = [ 
    {legend: "post_response_time", data: $post_response_time.rate_in(RESP_RENGES)},
    {legend: "get_response_time", data: $get_response_time.rate_in(RESP_RENGES) }
  ]
  make_graph title, rate_dataset, RESP_RENGES, "#{title}_rate.png", {x_axis_label: "ms", y_axis_label: "%"}, 'Bar'

#   post_response_time_png = "group_msg_test_post_response_time.png"
#   $post_response_time.graph RESP_RENGES, "post response time(ms)", {}, post_response_time_png
#   puts "post响应时间图片生成至#{post_response_time_png}"

#   get_response_time_png = "group_msg_test_get_response_time.png"
#   $get_response_time.graph RESP_RENGES, "get response time(ms)", {}, get_response_time_png
#   puts "get响应时间图片生成至#{get_response_time_png}"
end
