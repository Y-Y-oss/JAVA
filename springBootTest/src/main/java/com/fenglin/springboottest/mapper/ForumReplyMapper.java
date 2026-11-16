package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.ForumReply;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * 论坛回复数据层
 */
public interface ForumReplyMapper extends BaseMapper<ForumReply> {

    /** 某帖子的回复列表（带回复人信息），按时间正序 */
    @Select("SELECT r.id, r.post_id, r.user_id, r.content, r.create_time, " +
            "       u.username, u.nickname, u.avatar " +
            "FROM lc_forum_reply r JOIN lc_user u ON u.id = r.user_id " +
            "WHERE r.post_id = #{postId} " +
            "ORDER BY r.create_time ASC, r.id ASC")
    List<Map<String, Object>> selectReplies(@Param("postId") Long postId);
}
