#!/usr/bin/env ruby
#encoding=utf-8
require 'net/http'
require 'json'
require "open-uri"

require './helpers/spec_helper.rb'
require './class/user.rb'
require "./helpers/business_helper"


include SpecHelper
include BusinessHelper


online_users_at_same_time = 9000
$login_retry_times = 0
offset = 1
send_times = 20

begin
  conversation_ids = []
  user_ids = []
  admin_user = User.new(login_name: "100", password: "111111").login
  header = admin_user.header
#   response = get "/api/v1/users", {limit: online_users_at_same_time + 1}, admin_user.header
  # log response, 0
#   response[:items].each do |item|
#     user_ids << { id: item[:id], emp_code: item[:emp_code] }
#   end

  threads = []
  error_responses = []
  online_users_at_same_time.times do |n|
    thread = Thread.new do
      # TODO：在新线程里建立推送连接
      loop do
        get "/api/v1/describe_api", {}, header
      end
      
    end
    threads << thread
  end

  threads.each {|t| t.join}


  puts "登陆失败次数：#{$login_retry_times}"
  puts "post次数为： #{$total_post}"
  puts "get次数为： #{$total_get}"

  puts "错误的response数：#{error_responses.size}"

  puts "post请求rainbows超时： #{$errors_count_post}"
  puts "get请求rainbows超时：#{$errors_count_get}"

  puts "post请求nginx超时： #{$time_out_count_post}"
  puts "get请求nginx超时： #{$time_out_count_get}"
rescue Interrupt
  STDERR.print "登陆失败次数：#{$login_retry_times}\n"
  STDERR.print "post次数为： #{$total_post}\n"
  STDERR.print "get次数为： #{$total_get}\n"

  STDERR.print "错误的response数：#{error_responses.size}\n"

  STDERR.print "post请求rainbows超时： #{$errors_count_post}\n"
  STDERR.print "get请求rainbows超时：#{$errors_count_get}\n"

  STDERR.print "post请求nginx超时： #{$time_out_count_post}\n"
  STDERR.print "get请求nginx超时： #{$time_out_count_get}\n"
end
