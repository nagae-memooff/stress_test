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


# online_users_at_same_time = 100
user_region = (1..100)
$login_retry_times = 0
offset = 1
send_times = 5
pages = (1..50)

admin_user = User.new(login_name: "100", password: "111111").login
$header = admin_user.header

begin
  pages.each do |page|
    log "第#{page}页", 5
    user_ids = []
    response = get "/api/v1/users", {limit: user_region.count, page: page}, $header
#       log response, 5
    response[:items].each do |item|
      user_ids << { id: item[:id], emp_code: item[:emp_code] }
    end

    #   log user_ids, 5

    threads = []
    error_responses = []
    user_region.each do |n|
      thread = Thread.new do
        # TODO：在新线程里建立推送连接
        user1 = "aaa"
        loop do
          user1 = User.new(login_name: user_ids[n-1][:emp_code], password: 111111).login
#           log user1.response_obj, 5
          break unless user1.response_obj[:id].nil?
          $login_retry_times += 1
          #         log user1.response_obj, 5
          log "用户#{user_ids[n-1][:emp_code]}登陆失败，稍后重试", 5
        end

        loop do
          resp = user1.regist_device
          log resp, 5
          break if (resp[:status] == "Registered!" || resp[:status] == "Updated!")
        end

      end
      threads << thread
    end

    threads.each {|t| t.join}

  end


  puts "post次数为： #{$total_post}"
  puts "get次数为： #{$total_get}"


  puts "post请求rainbows超时： #{$errors_count_post}"
  puts "get请求rainbows超时：#{$errors_count_get}"

  puts "post请求nginx超时： #{$time_out_count_post}"
  puts "get请求nginx超时： #{$time_out_count_get}"
rescue Interrupt
  STDERR.print "登陆失败次数：#{$login_retry_times}\n"
  STDERR.print "post次数为： #{$total_post}\n"
  STDERR.print "get次数为： #{$total_get}\n"


  STDERR.print "post请求rainbows超时： #{$errors_count_post}\n"
  STDERR.print "get请求rainbows超时：#{$errors_count_get}\n"

  STDERR.print "post请求nginx超时： #{$time_out_count_post}\n"
  STDERR.print "get请求nginx超时： #{$time_out_count_get}\n"
end
