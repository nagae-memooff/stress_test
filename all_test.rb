#!/usr/bin/env ruby
#encoding=utf-8

def test_the_case file_name, seconds=300
  t = Thread.new do
    system file_name
  end
  
  t.run and sleep seconds

  puts "已运行#{seconds/60}分钟，回车继续"
  gets
  Thread.kill t
end

# test_the_case "testtest.rb", 5
test_the_case "login_test.rb", 600
test_the_case "private_message_test.rb", 600
test_the_case "group_message_test.rb", 600
test_the_case "new_group_message_test.rb", 600
test_the_case "image_test.rb", 600
puts "全部测试已结束"
