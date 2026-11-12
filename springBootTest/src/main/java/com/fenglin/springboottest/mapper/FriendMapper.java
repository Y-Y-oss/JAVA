package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Friend;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * 好友关系数据层
 */
public interface FriendMapper extends BaseMapper<Friend> {

    /** 我的好友列表（双向同意的关系里，取 friend_id=别人 那一侧），带对方用户名/昵称 */
    @Select("SELECT f.id, f.friend_id, u.username, u.nickname, f.create_time " +
            "FROM lc_friend f JOIN lc_user u ON u.id = f.friend_id " +
            "WHERE f.user_id = #{userId} AND f.status = 1 " +
            "ORDER BY f.create_time DESC")
    List<Map<String, Object>> selectFriends(@Param("userId") Long userId);

    /** 收到的待验证申请（friend_id=我 且 status=0），带申请人信息 */
    @Select("SELECT a.id, a.user_id, u.username, u.nickname, a.create_time " +
            "FROM lc_friend a JOIN lc_user u ON u.id = a.user_id " +
            "WHERE a.friend_id = #{userId} AND a.status = 0 " +
            "ORDER BY a.create_time DESC")
    List<Map<String, Object>> selectPendingIncoming(@Param("userId") Long userId);

    /** 我发出的待验证申请 */
    @Select("SELECT a.id, a.friend_id, u.username, u.nickname, a.create_time " +
            "FROM lc_friend a JOIN lc_user u ON u.id = a.friend_id " +
            "WHERE a.user_id = #{userId} AND a.status = 0 " +
            "ORDER BY a.create_time DESC")
    List<Map<String, Object>> selectPendingOutgoing(@Param("userId") Long userId);
}
