#!/usr/bin/env ruby
#encoding=utf-8

csv = "邮箱, 姓名, 职务, 手机号, 备用手机号, 工作电话, 工号, 部门标识, 排序, 扩展1, 扩展2, 扩展3, 扩展4, 扩展5, 扩展6, 扩展7, 扩展8, 扩展9, 扩展10\n"
dept_code = "1001"

from = ARGV[0] || 10060001
to = ARGV[1] || 10075001
      
user_region = (from..to)
user_region.each do |n|
  csv << "rand_#{n}@rand.com,美工#{n}号,美工,,,,#{n},#{dept_code},,,,,,,,,,,\n"
end

File.open("./user.csv", 'w') do |f|
  f.write csv
end
