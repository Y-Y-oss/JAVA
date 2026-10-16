package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.Archive;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * 时光档案数据层
 */
public interface ArchiveMapper extends BaseMapper<Archive> {

    /**
     * 查询公开档案墙（visibility=1），带作者用户名，按更新时间倒序
     */
    @Select("SELECT a.id, a.user_id, u.username, a.title, a.content, a.archive_date, a.tag, " +
            "a.create_time, a.update_time " +
            "FROM lc_archive a JOIN lc_user u ON u.id = a.user_id " +
            "WHERE a.visibility = 1 " +
            "ORDER BY a.update_time DESC LIMIT #{offset}, #{size}")
    List<Map<String, Object>> selectPublicWall(@Param("offset") long offset, @Param("size") long size);

    /**
     * 公开档案总数（档案墙分页用）
     */
    @Select("SELECT COUNT(*) FROM lc_archive WHERE visibility = 1")
    long countPublic();

    /**
     * 搜索公开档案墙（visibility=1）：按 标题/内容/标签 模糊匹配，带作者用户名，
     * 按更新时间倒序。q 为空时退化为「列出全部公开档案」。
     */
    @Select("SELECT a.id, a.user_id, u.username, a.title, a.content, a.archive_date, a.tag, " +
            "a.create_time, a.update_time " +
            "FROM lc_archive a JOIN lc_user u ON u.id = a.user_id " +
            "WHERE a.visibility = 1 " +
            "AND (a.title LIKE CONCAT('%',#{q},'%') " +
            "     OR a.content LIKE CONCAT('%',#{q},'%') " +
            "     OR a.tag LIKE CONCAT('%',#{q},'%')) " +
            "ORDER BY a.update_time DESC LIMIT #{offset}, #{size}")
    List<Map<String, Object>> searchPublicWall(@Param("q") String q, @Param("offset") long offset, @Param("size") long size);

    /**
     * 搜索公开档案总数（与 searchPublicWall 的过滤条件保持一致）
     */
    @Select("SELECT COUNT(*) FROM lc_archive WHERE visibility = 1 " +
            "AND (title LIKE CONCAT('%',#{q},'%') " +
            "     OR content LIKE CONCAT('%',#{q},'%') " +
            "     OR tag LIKE CONCAT('%',#{q},'%'))")
    long countSearchPublic(@Param("q") String q);
}
