package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.User;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

/**
 * 用户数据层
 */
public interface UserMapper extends BaseMapper<User> {

    /**
     * 根据手机号查询用户（用于判断手机号是否已注册）
     */
    @Select("SELECT * FROM lc_user WHERE phone = #{phone} LIMIT 1")
    User selectByPhone(@Param("phone") String phone);

    /**
     * 根据用户名查询用户（登录时优先按用户名匹配）
     */
    @Select("SELECT * FROM lc_user WHERE username = #{username} LIMIT 1")
    User selectByUsername(@Param("username") String username);
}
