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


user_region = (100...130)
meirenzhibiao = 100

# # 全网管理员创建新社区
# super_admin = User.new(SUPER_ADMIN).login
# response =  post "/api/v1/networks", NETWORK_1, super_admin.header
# 
# log "response: #{response}", 5
# sleep 5

# 社区管理员登陆
user = User.new(login_name: "100", password: "111111").login
$dept_admin = user
$network_id = get("/api/v1/networks/current.json", {}, user.header)[:items].first[:id]
# group_id = 22

# 创建许多个用户并加入工作圈"
threads = []
user_region.each do |n|
  threads << Thread.new do
    meirenzhibiao.times do |m|
      user_params = {network_id: $network_id }.merge get_a_random_user(n * meirenzhibiao + m)
      loop do
        #       log "创建用户 #{n * meirenzhibiao + m}", 0
        resp = post "/api/v1/users", user_params, $dept_admin.header

        break if resp[:code] == 200
        log "注册用户出错，稍后重试", 5
        sleep rand 5
      end
      #       log resp, 0
      sleep rand 10

      loop do
        user = User.new(user_params).login
        #         break unless user.response_obj[:id].nil?

        resp = user.regist_device
        break if (resp[:status] == "Registered!" || resp[:status] == "Updated!")
        log "注册设备出错，稍后重试", 5

        sleep rand 5
      end
    end

  end
end

threads.each {|t| t.join}


# puts "post请求统计总数为：#{$total_post}，实际总数为：#{meirenzhibiao * user_region.count + 1}"
puts "post请求总共出现错误： #{$errors_count_post}"
puts "get请求总共出现错误：#{$errors_count_get}"

puts "post请求超时： #{$time_out_count_post}"
puts "get请求超时： #{$time_out_count_get}"
