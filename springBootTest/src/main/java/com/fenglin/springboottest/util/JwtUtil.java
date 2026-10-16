package com.fenglin.springboottest.util;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.enums.UserRole;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

/**
 * JWT 工具：登录后签发 token，请求时解析 token
 */
@Component
public class JwtUtil {

    /** JWT 签名密钥（生产环境请改为配置项或 KMS 下发，长度需 >= 32 字节） */
    @Value("${jwt.secret:LinkClickAuthLocalDevSecretKey_时光代理人_2026}")
    private String secret;

    /** token 有效期（秒），默认 7 天 */
    @Value("${jwt.expire-seconds:604800}")
    private long expireSeconds;

    private SecretKey key() {
        return Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    /** token 中携带的密码版本号 claim 名 */
    public static final String CLAIM_PWD_VERSION = "pv";

    /** token 中携带的角色 claim 名 */
    public static final String CLAIM_ROLE = "role";

    /** 令牌类型 claim 名 */
    public static final String CLAIM_TYPE = "typ";

    /** 令牌类型：访问令牌（业务接口只认这个） */
    public static final String TYPE_ACCESS = "access";

    /**
     * 生成访问令牌（携带角色与当前密码版本号，有效期为 jwt.expire-seconds）
     */
    public String generateToken(User user) {
        return generateToken(user, expireSeconds);
    }

    /**
     * 生成访问令牌，可指定有效期（秒）
     *
     * @param expireSeconds 有效期（秒）
     */
    public String generateToken(User user, long expireSeconds) {
        Date now = new Date();
        return Jwts.builder()
                .subject(String.valueOf(user.getId()))
                .claim("username", user.getUsername())
                .claim("phone", user.getPhone())
                .claim(CLAIM_ROLE, user.getRole() == null ? UserRole.USER.getCode() : user.getRole())
                .claim(CLAIM_PWD_VERSION, pwdVersionOf(user))
                .claim(CLAIM_TYPE, TYPE_ACCESS)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + expireSeconds * 1000L))
                .signWith(key())
                .compact();
    }

    /**
     * 判断令牌是否确为访问令牌。
     *
     * <p>只携带令牌原文是判断不出来的——解析出 typ=access 只能说明签发时它是访问令牌，
     * 中间可能被换过。真正的校验仍然要看业务接口本身认不认。</p>
     */
    public boolean isAccessToken(String token) {
        try {
            Object typ = parseToken(token).get(CLAIM_TYPE);
            return TYPE_ACCESS.equals(typ);
        } catch (Exception e) {
            return false;
        }
    }

    /** 取用户的密码版本号（兜底为 1，避免历史数据为 null 时签发出 null claim） */
    private int pwdVersionOf(User user) {
        return user.getPwdVersion() == null ? 1 : user.getPwdVersion();
    }

    /**
     * 解析 token，过期或签名错误会抛出异常
     */
    public Claims parseToken(String token) {
        return Jwts.parser()
                .verifyWith(key())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * 取出 token 的过期时间（毫秒时间戳），用于设置黑名单过期时间
     */
    public long getExpirationMillis(String token) {
        return parseToken(token).getExpiration().getTime();
    }

    /**
     * 从 token 中取出用户 id
     */
    public Long getUserId(String token) {
        return Long.valueOf(parseToken(token).getSubject());
    }

    /**
     * 从 token 中取出签发时的密码版本号
     */
    public int getPwdVersion(String token) {
        Claims claims = parseToken(token);
        Object pv = claims.get(CLAIM_PWD_VERSION);
        return pv instanceof Integer ? (Integer) pv : 1;
    }

    /**
     * 从 token 中取出签发时的角色
     */
    public UserRole getRole(String token) {
        Claims claims = parseToken(token);
        Object role = claims.get(CLAIM_ROLE);
        return UserRole.of(role instanceof String ? (String) role : null);
    }

    public long getExpireSeconds() {
        return expireSeconds;
    }
}
