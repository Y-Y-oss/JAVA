package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 刷新令牌实体，对应数据库中的 lc_refresh_token 表
 *
 * <p>数据库里只保存令牌的 SHA-256 摘要，原始令牌（只有前端持有）从不落库。
 * 一旦原始令牌泄露，攻击者拿到的只是一串无法反查的哈希。</p>
 */
@Data
@TableName("lc_refresh_token")
public class RefreshToken implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 所属用户 id */
    private Long userId;

    /** 刷新令牌的 SHA-256 摘要 */
    private String tokenHash;

    /** 令牌族：同一族内的令牌成链轮换，整族作废时一次性吊销 */
    private String familyId;

    /** 过期时间 */
    private LocalDateTime expiresAt;

    /**
     * 吊销状态：
     * 0-有效；1-已轮换（正常使用）；2-已吊销（登出 / 重放检测 / 过期清理）
     */
    private Integer revoked;

    /** 吊销原因：rotate / logout / replay / expired / manual */
    private String revokedReason;

    /** 轮换后接替它的令牌摘要，用于沿链追溯整条会话 */
    private String replacedBy;

    /** 创建时间 */
    private LocalDateTime createTime;
}
