#!/usr/bin/env ruby
#encoding=utf-8

# 以文本形式保存所需执行命令的字符串
LOG_FILE_NAME = ARGV.first || 'sidekiq.log'

# 是否对响应时间结果消除误差。true则删掉最长和最短的50条记录
XIAOCHUWUCHA = false

@ranges = [
  (0.0   ... 0.2),
  (0.2   ... 0.3),
  (0.3   ... 0.4),
  (0.4   ... 0.5),
  (0.5   ... 0.6),
  (0.6   ... 0.7),
  (0.7   ... 0.8),
  (0.8   ... 0.9),
  (0.9   ... 1.0),
  (1.0   ... 1.2),
  (1.2   ... 1.3),
  (1.3   ... 1.7),
  (1.7   ... 2.0),
  (2.0   ... 999),
]

@processors = [
  "ConversationMessageProcessor",
  "ConversationMessageDispatchProcessor",
  "ActivityProcessor",
  "UserGroupsChangedProcessor"
]

# 执行命令，利用命令输出生成时间数组

@threads = []

def generate_graph times
  str = "*"
  times.to_i.times do |n|
    str << "*"
  end

  "#{str} : #{times} %"
end

def times_in_range array, range
  array.count {|time| range === time } || 0
end

def tongji processor, log_file_name=LOG_FILE_NAME
  # 先对数组排序，再删掉最小和最大的50条数据
  Thread.new do
    result = ""
    processer_filter_cmd = 'grep ' + processor + '.*done /home/ewhine/deploy/ewhine_NB/current/log/' + log_file_name + \
      ' | sed "s/.*' + processor + '.*INFO: done: \([0-9]\+\.[0-9]\+\) sec/\1/g"'

    ori_array = `#{processer_filter_cmd}`.split("\n").map {|element| element.to_f}


    array = ori_array.sort
    array = array[50..-50] if XIAOCHUWUCHA
    result << "#{processor}：\n"

    if ori_array.size < 1
      result << "#{processor}数据太少，请增加测试数据量！"
    else
      sum_time = array.inject {|sum, n| sum + n }
      total_times = array.size
      average_time = sum_time / total_times

      times_array = []
      @ranges.each do |range|
        times = times_in_range(array, range).to_f
        rate = ((times / total_times ) * 10000).to_i / 100 
        times_array << { range => { times: times, rate: rate }}
        result << "#{range}区间：#{generate_graph rate}\n"
      end

      result << "#{XIAOCHUWUCHA ? "已" : "未"}去除最高和最低的50个样本\n"
      result << "样本数： #{total_times}， 总共处理时间：#{sum_time}秒\n"
      result << "平均响应时间时间：#{average_time * 1000} 毫秒\n"
      result << "=====================================================\n"
    end
    puts result
  end
end

@processors.each {|processor| @threads << tongji(processor) }

@threads.each {|t| t.join}

alarm
