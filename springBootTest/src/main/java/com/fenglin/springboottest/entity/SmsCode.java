package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 短信验证码实体，对应数据库中的 lc_sms_code 表
 */
@Data
@TableName("lc_sms_code")
public class SmsCode implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 手机号 */
    private String phone;

    /** 验证码 */
    private String code;

    /** 场景：register-注册 */
    private String scene;

    /** 过期时间 */
    private LocalDateTime expireTime;

    /** 是否已使用：0-未使用，1-已使用 */
    private Integer consumed;

    /** 创建时间 */
    private LocalDateTime createTime;
}
