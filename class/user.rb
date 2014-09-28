#encoding=utf-8
class User
  require './helpers/spec_helper'
  require './helpers/mqtt_helper'
  
  include SpecHelper
  include MqttHelper

  attr_accessor :login_name, :password, :access_token, :network_id, :response_obj

  def self.loop_login options, sleep_seconds
    loop do
      sleep sleep_seconds # 平摊登陆请求，使得每秒约30个人登陆
      user1 = User.new(options).login
      return user1 unless user1.response_obj[:id].nil?
      $login_retry_times += 1
      log "用户#{options[:login_name]}登陆失败，稍后重试", 5
    end
  end

  def login
    response = post '/oauth2/token', params
    self.access_token = response[:access_token]
    log response

    response = get '/api/v1/users/current/home_user', {}, Authorization: "Bearer #{access_token}"
    self.network_id = response[:network_id]
    log response

    response = get '/api/v1/users/current', {}, header
    self.response_obj = response
    log response
    self
  end

  def view_group group_id
    path = "/api/v1/messages/in_group/#{group_id}"
    params = {threaded: "extended", network_id: network_id}
    response = get path, params, header
    log response
    response
  end

  def joined_groups
    self.response_obj[:joined_groups]
  end

  def send_messege group_id, message, options={cc: ""}
    params = {group_id: group_id, body: message, threaded: "extended"}
    post_to_messages params, options
  end

  def regist_device options={}
    default_options = {
      device_uuid: "10000#{id}", device_name: 'android device',
      apn_token: '766593005693248778', device_sn: '076b62c5',
      device_os_version: '4.3',
      device_fingerprint: 'samsung/hltezm/hlte:4.3/JSS15J/N9008VZMUBNA2:user/release-keys'
    }

    params = default_options.merge options
    path = "/api/v1/users/current/devices.json"

    response = post path, params, header
    response
  end

  def direct_send_minxin ids, message, options={}
    id_array_str = 
      if ids.is_a? Array
        ids.join ","
      else
        ids.to_s
      end
    
    params = {direct_to_user_ids: id_array_str, body: message}
    post_to_messages params, options, "/api/v1/conversations"
  end

  def send_minxin_by_conversation_id conversation_id, message, options={}
    params = {body: message}
    post_to_messages params, options, "/api/v1/conversations/#{conversation_id}/messages"
  end

  def create_story_msg group_id, story, options={cc: ""}
    params = {group_id: group_id, story: story.to_json, threaded: "extended"}
    post_to_messages params, options
  end

  def initialize options
     @login_name = options[:login_name]
     @password = options[:password]
  end

  def params
    p = {grant_type: GRANT_TYPE, login_name: self.login_name, password: self.password,
         app_id: APP_ID, app_secret: APP_SECRET}
    p
  end

  def header
    {Authorization: "Bearer #{access_token}", NETWORK_ID: network_id}
  end

  def id
    response_obj[:id]
  end

  def name
    response_obj[:name]
  end

  def receive_mqtt in_background=false, &p
    mqtt_options = MQTT_OPTIONS.merge client_id: self.response_obj[:account_id].to_s
    if in_background
      Thread.start { subscribe response_obj[:account_channel], mqtt_options, &p }
    else
      subscribe response_obj[:account_channel], mqtt_options, &p
    end
  end

  def post_to_messages params, options, url="/api/v1/messages"
    params = params.merge options
    response = post url, params, header
    log response
    response
  end

  def send_pic_to_conversation pic_path, conversation_id
    url = "http://#{HOSTNAME}:#{PORT}/api/v1/uploaded_files"
    pic_path = File.expand_path  pic_path
    pic = File.new pic_path, "rb"

    response_str = RestClient.post(url, {'uploading[]'=> [{data: pic}]}, self.header)
    response = JSON.parse response_str, symbolize_names: true
#     puts response.inspect
    pic_id = response.first[:id]

    response = post "/api/v1/conversations/#{conversation_id}/messages", {'attached[]'=> "uploaded_file:#{pic_id}"}, self.header
    response
  end

end
