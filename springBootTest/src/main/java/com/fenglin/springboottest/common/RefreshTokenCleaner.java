package com.fenglin.springboottest.common;

import com.fenglin.springboottest.mapper.RefreshTokenMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * 刷新令牌清理。
 *
 * <p>刷新令牌过期后就不可能再被使用，但它占着一张表。这里定期把「过期时间已过」的行删掉。
 * 注意**只删已过期的行**：仍然有效的行哪怕被吊销了也要留着——吊销状态是重放检测的依据，
 * 一旦删掉，「同一枚令牌用第二次」就查不出痕迹了。</p>
 */
@Slf4j
@Component
public class RefreshTokenCleaner {

    @Autowired
    private RefreshTokenMapper refreshTokenMapper;

    /**
     * 每天凌晨 4:10 清理一次（错开其他定时任务）
     */
    @Scheduled(cron = "0 10 4 * * ?")
    public void cleanUpTask() {
        cleanExpired();
    }

    /**
     * 删除已过期的记录，返回删除条数
     */
    public int cleanExpired() {
        int deleted = refreshTokenMapper.deleteExpired(LocalDateTime.now());
        if (deleted > 0) {
            log.info("清理过期刷新令牌 {} 条", deleted);
        }
        return deleted;
    }
}
