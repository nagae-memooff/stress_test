#!/usr/bin/env ruby
#encoding=utf-8

LOG_PATH = ARGV[0] || "/home/ewhine/system_info.log"

commands = [
  "mqtt3d",
  "sidekiq",
  "mysql",
  "redis",
  "nginx",
  "rainbows master",
  'rainbows worker\[0\]',
  'rainbows worker\[1\]',
  'rainbows worker\[2\]',
  'rainbows worker\[3\]',
  'rainbows worker\[4\]'
]

def analyze  command_name = "rainbows", print_clms = 3
  #   awk_clms = "$#{print_clms.join(", $")}"
  awk_clms = "$#{print_clms}"
  cmd = "cat #{LOG_PATH} |grep \"#{command_name}\"|awk '{print #{awk_clms}}'"

  res_array = `#{cmd}`.split("\n").map {|n| n.to_f}

  if res_array.any?
    sum = res_array.inject {|s, n| s + n }
    max = res_array.max
    size = res_array.size
    average = sum / size
  else
    average = "0"
    max = 0
  end

  [average, max]
end

res = ""
commands.each do |command_name|
  res << "#{command_name}\n"
  [3,4,6].each do  |clm|
    average, max = analyze command_name, clm
    clm_name =
      case clm
      when 3
        "CPU%"
      when 4
        "MEM%"
      when 6
        "MEM"
      end
    res << "  #{clm_name}:\n"
    res << "    average: #{average}\n"
    res << "    max: #{max}\n"
  end
end
puts res
