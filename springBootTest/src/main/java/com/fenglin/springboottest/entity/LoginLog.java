package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 登录日志实体，对应数据库 lc_login_log 表
 *
 * <p>每次登录（成功或失败）都会追加一条记录，永不覆盖，用于留存完整的登录历史，
 * 区别于 lc_user.last_login_time（仅记录「最近一次」）。</p>
 */
@Data
@TableName("lc_login_log")
public class LoginLog implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 登录用户 id（登录失败且账号不存在时为 null） */
    private Long userId;

    /** 登录时使用的账号名 */
    private String username;

    /** 登录方式：password-账号密码 */
    private String loginType;

    /** 登录来源 IP */
    private String ip;

    /** 客户端 User-Agent */
    private String userAgent;

    /** 是否成功：1-成功，0-失败 */
    private Integer success;

    /** 失败原因 */
    private String failReason;

    /** 登录发生时间 */
    private LocalDateTime loginTime;

    /** 记录创建时间 */
    private LocalDateTime createTime;
}
