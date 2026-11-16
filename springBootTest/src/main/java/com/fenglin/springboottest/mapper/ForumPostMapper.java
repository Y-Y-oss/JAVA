package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.ForumPost;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * 论坛帖子数据层
 */
public interface ForumPostMapper extends BaseMapper<ForumPost> {

    /** 帖子列表（带作者信息与回复数），按发帖时间倒序 */
    @Select("SELECT p.id, p.user_id, p.title, p.content, p.reply_count, p.create_time, " +
            "       u.username, u.nickname, u.avatar " +
            "FROM lc_forum_post p JOIN lc_user u ON u.id = p.user_id " +
            "ORDER BY p.create_time DESC LIMIT #{offset}, #{size}")
    List<Map<String, Object>> selectPostList(@Param("offset") long offset, @Param("size") int size);

    /** 单个帖子详情（带作者信息） */
    @Select("SELECT p.id, p.user_id, p.title, p.content, p.reply_count, p.create_time, " +
            "       u.username, u.nickname, u.avatar " +
            "FROM lc_forum_post p JOIN lc_user u ON u.id = p.user_id " +
            "WHERE p.id = #{postId}")
    Map<String, Object> selectPostDetail(@Param("postId") Long postId);
}
