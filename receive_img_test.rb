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


online_users_at_same_time = 100
$login_retry_times = 0
$received_msgs = 0
$start_at = nil
$end_at = nil
offset = 1

admin_user = User.new(login_name: "100", password: "111111").login
response = get "/api/v1/users", {limit: online_users_at_same_time + offset}, admin_user.header

msg_bodys = []
times = []
# log response, 0
user_ids = ( response[:items].map {|item| {id: item[:id], emp_code: item[:emp_code]}} )[offset..-1]

threads = []
online_users_at_same_time.times do |n|
  thread = Thread.new do
    # TODO：在新线程里建立推送连接
    user1 = User.loop_login({login_name: user_ids[n][:emp_code], password: 111111}, ( online_users_at_same_time * rand / 30 ).to_i)
    puts "用户#{user1.id}登陆完毕"
    #       user1.receive_mqtt
    begin
      user1.receive_mqtt do |topic, msg|
        puts "#{user1.id}收到消息"
      end
    rescue MQTT::ProtocolException
      puts "捕获到MQTT::ProtocolException"
    end
  end
  threads << thread
end

threads.each {|t| t.join}
