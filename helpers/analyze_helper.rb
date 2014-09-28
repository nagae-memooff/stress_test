module AnalyzeHelper
  require "gruff"
  MQTT_RECEIVE_RANGES = [
    (0  ... 1),
    (1  ... 2),
    (2  ... 3),
    (3  ... 5),
    (5  ... 9),
    (9  ... 15),
    (15 ... 99)
  ]

  RESP_RENGES = [
    (00  ... 50),
    (50  ... 100),
    (100  ... 150),
    (150  ... 200),
    (200  ... 250),
    (300  ... 350),
    (350  ... 400),
    (400  ... 600),
    (600  ... 1000),
    (1000  ... 9999)
  ]
  def get_rate_array array, ranges
  end

  def make_graph title, dataset, x_axis_labels, file_name="gruff.png", options={}, gruff='Line'
    g = eval "Gruff::#{gruff}.new"
    # Gruff::Line.new
    # Gruff::Bezier.new
    # Gruff::StackedBar.new

    g.title_font_size = 32
    g.legend_font_size = 24
    g.marker_font_size = 16
    
    # 新建一个data数组用于保存API响应时间落在每个区间的比率
    g.title = title

    # 对每个区间求落在该区间的比率，并将比率加入data数组
    dataset.each do |data|
      g.data data[:legend], data[:data]
    end

    # 对options哈希中的每个key都认为是该表的属性
    options.each do |key, value|
      eval "g.#{key} = '#{value}'"
    end


    # 初始化横坐标相关变量
    labels, x = {}, 0
    x_axis_labels.each do |l|
      labels[x] = l.to_s
      x += 1
    end
    g.labels = labels

    g.write file_name
  end
end

class Array
  include AnalyzeHelper
  def avg
    sum = self.inject(0) {|s, n| s + n}
    sum / size
  end

  def times_in_range range
    self.count {|time| range === time } || 0
  end

  def generate_graph times
    str = "*"
    times.to_i.times do |n|
      str << "*"
    end

    "#{str} : #{times} %"
  end

  def rate_graph ranges, title="", options={}, file_name="gruff.png", gruff='Line'
    # 新建一个data数组用于保存API响应时间落在每个区间的比率
    datas = []

    # 对每个区间求落在该区间的比率，并将比率加入data数组
    ranges.each do |range|
      times = self.times_in_range range
      rate = ((times / size.to_f ) * 10000).to_i / 100 
      datas << rate
    end

    dataset = [{legend: title.to_sym, data: datas}]
    
    make_graph title, dataset, ranges, file_name, options, gruff
  end

  def graph title="time", options={}, file_name="gruff.png", gruff='Line'
    dataset = [{legend: title.to_sym, data: self }]
    make_graph title, dataset, [], file_name, options, gruff
  end

  def rate_in ranges
    # 新建一个data数组用于保存API响应时间落在每个区间的比率
    datas = []

    # 对每个区间求落在该区间的比率，并将比率加入data数组
    ranges.each do |range|
      times = self.times_in_range range
      rate = ((times / self.size.to_f ) * 10000).to_i / 100 
      datas << rate
    end

    datas
  end
end
