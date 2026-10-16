package com.fenglin.springboottest.dto;

import lombok.Data;

/**
 * 刷新令牌请求参数
 *
 * <pre>
 * POST /api/auth/refresh  { "refreshToken": "xxxx" }
 * </pre>
 */
@Data
public class RefreshTokenDTO {

    /** 前端保存的刷新令牌原文（服务端只比对它的 SHA-256 摘要） */
    private String refreshToken;
}
