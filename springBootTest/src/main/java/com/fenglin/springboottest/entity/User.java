package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 用户实体，对应数据库中的 lc_user 表
 */
@Data
@TableName("lc_user")
public class User implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 用户名 */
    private String username;

    /** 手机号 */
    private String phone;

    /** 密码（BCrypt 哈希） */
    private String password;

    /** 昵称 */
    private String nickname;

    /** 账号状态：1-正常，0-禁用 */
    private Integer status;

    /** 角色：user（普通用户）/ admin（管理员），对应 enums.UserRole */
    private String role;

    /** 密码版本号：修改密码时 +1，使所有已签发的旧 token 立即失效 */
    private Integer pwdVersion;

    /** 最近一次登录时间 */
    private LocalDateTime lastLoginTime;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
