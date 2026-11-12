package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.ArchiveComment;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * 时光档案评论数据层
 */
public interface ArchiveCommentMapper extends BaseMapper<ArchiveComment> {

    /**
     * 档案评论列表（带评论人用户名），按评论时间升序
     */
    @Select("SELECT c.id, c.archive_id, c.user_id, u.username, c.content, c.create_time " +
            "FROM lc_archive_comment c JOIN lc_user u ON u.id = c.user_id " +
            "WHERE c.archive_id = #{archiveId} " +
            "ORDER BY c.create_time ASC, c.id ASC")
    List<Map<String, Object>> selectCommentsWithUser(@Param("archiveId") Long archiveId);
}
