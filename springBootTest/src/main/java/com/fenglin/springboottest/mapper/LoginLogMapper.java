package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.LoginLog;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * 登录日志数据层
 */
public interface LoginLogMapper extends BaseMapper<LoginLog> {

    /**
     * 分页查询登录日志（按 id 倒序，可选按用户名 id / 成功标志过滤）
     */
    @Select("SELECT * FROM lc_login_log " +
            "WHERE (#{userId} IS NULL OR user_id = #{userId}) " +
            "AND (#{success} IS NULL OR success = #{success}) " +
            "ORDER BY id DESC LIMIT #{offset}, #{size}")
    List<LoginLog> selectPage(@Param("userId") Long userId,
                              @Param("success") Integer success,
                              @Param("offset") long offset,
                              @Param("size") long size);

    /**
     * 统计登录日志条数（可选按用户名 id / 成功标志过滤）
     */
    @Select("SELECT COUNT(*) FROM lc_login_log " +
            "WHERE (#{userId} IS NULL OR user_id = #{userId}) " +
            "AND (#{success} IS NULL OR success = #{success})")
    long count(@Param("userId") Long userId, @Param("success") Integer success);
}
