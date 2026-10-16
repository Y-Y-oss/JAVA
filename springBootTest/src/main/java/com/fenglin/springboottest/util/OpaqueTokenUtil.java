package com.fenglin.springboottest.util;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * 不透明令牌（opaque token）生成与摘要工具，专供刷新令牌使用。
 *
 * <p>为什么不直接把 refresh 也做成 JWT：JWT 是自包含的，服务端不落状态就无法吊销。
 * 而刷新令牌恰恰是「续期的凭证」，必须能被服务端随时吊销（登出、改密、检测到重放）。
 * 所以这里换成 32 字节随机串，库里只留 SHA-256 摘要——库被拖走也拿不出可用的令牌。</p>
 */
public final class OpaqueTokenUtil {

    /** 随机字节数，256 位熵 */
    private static final int BYTES = 32;

    private static final SecureRandom RANDOM = new SecureRandom();

    private OpaqueTokenUtil() {
    }

    /** 生成一枚不透明令牌（Base64URL 编码，不含会被转义的字符） */
    public static String generate() {
        byte[] raw = new byte[BYTES];
        RANDOM.nextBytes(raw);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(raw);
    }

    /**
     * 计算令牌摘要（十六进制小写），用于落库比对。
     *
     * <p>入参为空时直接拒绝，避免把「空串 / null」当成一种合法的「未入库」状态。</p>
     */
    public static String sha256Hex(String token) {
        if (token == null || token.isEmpty()) {
            throw new IllegalArgumentException("令牌不能为空");
        }
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(token.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(digest.length * 2);
            for (byte b : digest) {
                sb.append(Character.forDigit((b >> 4) & 0xF, 16));
                sb.append(Character.forDigit(b & 0xF, 16));
            }
            return sb.toString();
        } catch (Exception e) {
            throw new IllegalStateException("SHA-256 不可用", e);
        }
    }
}
