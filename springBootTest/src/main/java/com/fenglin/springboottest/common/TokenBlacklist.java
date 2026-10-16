package com.fenglin.springboottest.common;

import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 已登出的 token 黑名单。
 *
 * <p>token 本身是自包含的（JWT），服务端不存状态也能校验，代价是退出登录后到 token 自然过期之前
 * 依然可用。这里在内存中记录已登出的 token 及其过期时间，既能让「退出登录」立刻生效，
 * 又不需要引入 Redis；重启服务后黑名单清空，用户需要重新登录（可接受）。
 *
 * <p>生产环境建议换成 Redis 的 Set（key = 黑名单 token，TTL = token 剩余有效期），天然带过期能力。
 */
@Slf4j
@Component
public class TokenBlacklist {

    /** token -> 过期时间戳（毫秒） */
    private final Map<String, Long> tokens = new ConcurrentHashMap<>();

    /**
     * 加入黑名单，并记录过期时间用于自动清理
     */
    public void add(String token, long expiresAtMillis) {
        if (token == null || token.isEmpty()) {
            return;
        }
        tokens.put(token, expiresAtMillis);
    }

    /**
     * 判断 token 是否已登出（顺便清理已过期的记录）
     */
    public boolean isBlacklisted(String token) {
        if (token == null || token.isEmpty()) {
            return false;
        }
        Long expiresAt = tokens.get(token);
        if (expiresAt == null) {
            return false;
        }
        if (expiresAt <= System.currentTimeMillis()) {
            tokens.remove(token);
            return false;
        }
        return true;
    }

    /**
     * 清理过期记录，避免内存无限增长（由定时任务调用）
     */
    public int cleanExpired() {
        long now = System.currentTimeMillis();
        int removed = 0;
        for (Map.Entry<String, Long> entry : tokens.entrySet()) {
            if (entry.getValue() <= now) {
                tokens.remove(entry.getKey());
                removed++;
            }
        }
        return removed;
    }

    public int size() {
        return tokens.size();
    }

    /**
     * 每小时清理一次已过期的黑名单记录
     */
    @Scheduled(fixedDelay = 60 * 60 * 1000)
    public void cleanUpTask() {
        int removed = cleanExpired();
        if (removed > 0) {
            log.info("清理已登出 token {} 条，当前黑名单 size={}", removed, tokens.size());
        }
    }
}
