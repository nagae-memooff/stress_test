#encoding=utf-8
module BusinessHelper
  def check_send user1, user2, type, wait_seconds
    group_id = user1.joined_groups.first[:id]
    user_messages = user1.view_group group_id

    msg_type = "#{type}#{(1000 * rand).to_i}"
    test_msg = "用户#{user1.name}发送测试#{msg_type}"
    response =  if block_given? 
                  yield(user1, group_id, test_msg)
                else
                  user1.send_messege(group_id, test_msg)
                end
    thread_id = response[:items].first[:id]

    log "发送测试#{type}成功: #{test_msg}", 3

    log "等待#{wait_seconds}秒"
    sleep wait_seconds

    user2_messages = user2.view_group group_id
    response_msg = user2_messages[:items].first[:body][:plain]
#     puts user2_messages[:items].first

    log "#{user2.name}在组里查看#{msg_type}成功", 3


    test_reply_msg = "用户#{user2.name}测试回复#{msg_type}"
    response = user2.send_messege(group_id, test_reply_msg, replied_to_id: thread_id )
    log "#{user2.name}回复#{msg_type}成功，等待#{wait_seconds}秒", 3
    sleep wait_seconds

    user_messages = user1.view_group group_id
    ids = []
    threaded_extendeds = user_messages[:threaded_extended]
    threaded_extendeds.each {|k, v| ids << k.to_s.to_i }
    reply_id = ids.max.to_s.to_sym

    response_msg = threaded_extendeds[reply_id].first[:body][:plain]
    log "#{user1.name}查看回复#{type}成功", 3
  end
end
