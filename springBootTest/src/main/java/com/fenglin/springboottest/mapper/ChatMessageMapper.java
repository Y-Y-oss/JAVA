package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.ChatMessage;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * 好友私信数据层
 */
public interface ChatMessageMapper extends BaseMapper<ChatMessage> {

    /**
     * 与某位好友的聊天记录（双向），带发送方用户名/昵称/头像。
     * beforeId 为 0 时取最新一页；否则取比该 id 更早的一页（往上翻历史用）。
     */
    @Select("<script>" +
            "SELECT m.id, m.sender_id, m.receiver_id, m.content, m.read_flag, m.create_time, " +
            "       u.username, u.nickname, u.avatar " +
            "FROM lc_chat_message m JOIN lc_user u ON u.id = m.sender_id " +
            "WHERE (m.sender_id = #{me} AND m.receiver_id = #{friendId}) " +
            "   OR (m.sender_id = #{friendId} AND m.receiver_id = #{me}) " +
            "<if test='beforeId != null and beforeId > 0'> AND m.id &lt; #{beforeId} </if>" +
            "ORDER BY m.id DESC LIMIT #{limit}" +
            "</script>")
    List<Map<String, Object>> selectHistory(@Param("me") Long me,
                                            @Param("friendId") Long friendId,
                                            @Param("beforeId") Long beforeId,
                                            @Param("limit") int limit);

    /**
     * 会话总览：每个好友的最近一条消息 + 未读数 + 对方资料。
     * 没有聊天记录的好友也会出现（last_content 为 NULL），方便直接发起聊天。
     */
    @Select("SELECT f.friend_id, u.username, u.nickname, u.avatar, " +
            "       (SELECT c.content FROM lc_chat_message c " +
            "         WHERE (c.sender_id = #{me} AND c.receiver_id = f.friend_id) " +
            "            OR (c.sender_id = f.friend_id AND c.receiver_id = #{me}) " +
            "         ORDER BY c.id DESC LIMIT 1) AS last_content, " +
            "       (SELECT c.create_time FROM lc_chat_message c " +
            "         WHERE (c.sender_id = #{me} AND c.receiver_id = f.friend_id) " +
            "            OR (c.sender_id = f.friend_id AND c.receiver_id = #{me}) " +
            "         ORDER BY c.id DESC LIMIT 1) AS last_time, " +
            "       (SELECT COUNT(*) FROM lc_chat_message c " +
            "         WHERE c.sender_id = f.friend_id AND c.receiver_id = #{me} AND c.read_flag = 0) AS unread " +
            "FROM lc_friend f JOIN lc_user u ON u.id = f.friend_id " +
            "WHERE f.user_id = #{me} AND f.status = 1 " +
            "ORDER BY last_time DESC, u.username ASC")
    List<Map<String, Object>> selectConversations(@Param("me") Long me);

    /** 我收到的未读消息总数 */
    @Select("SELECT COUNT(*) FROM lc_chat_message WHERE receiver_id = #{me} AND read_flag = 0")
    long countUnread(@Param("me") Long me);
}
