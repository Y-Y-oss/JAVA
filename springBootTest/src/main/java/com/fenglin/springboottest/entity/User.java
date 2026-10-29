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

    /** 角色：user（普通用户）/ admin（管理员），对应 enums.UserRole（展示用，与 permission 保持一致） */
    private String role;

    /**
     * 权限：1-默认权限（普通用户，进入后台管理系统），0-管理员权限（可看到后台管理入口并登录后台）
     * <p>注意：后台管理系统的可见性与可登录性统一以本字段为准。</p>
     */
    private Integer permission;

    /** 密码版本号：修改密码时 +1，使所有已签发的旧 token 立即失效 */
    private Integer pwdVersion;

    /** 最近一次登录时间 */
    private LocalDateTime lastLoginTime;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
