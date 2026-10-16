package com.fenglin.springboottest.common;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.entity.SmsCode;
import com.fenglin.springboottest.mapper.SmsCodeMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * 过期短信验证码清理。
 *
 * <p>验证码本身 5 分钟就过期，但表里「已过期」的行会一直留着：既占空间，也会让
 * `selectRecent`（按 create_time 倒序取最近 5 条）在限频判断时读到一堆垃圾行。
 * 这里定期把过期时间超过保留时长的记录删掉，保留时长给得比验证码有效期宽裕得多，
 * 不会影响任何正在进行的校验。</p>
 *
 * <p>生产环境如果验证码量大，建议直接改成按 expire_time 的定时归档任务。</p>
 */
@Slf4j
@Component
public class SmsCodeCleaner {

    /** 保留时长：只删除「过期时间早于 当前 - retentionHours」的记录 */
    @Value("${auth.sms.cleanup-retention-hours:24}")
    private int retentionHours;

    @Autowired
    private SmsCodeMapper smsCodeMapper;

    /**
     * 每天凌晨 3:20 清理一次（错开整点，避免和其他定时任务挤在一起）
     */
    @Scheduled(cron = "0 20 3 * * ?")
    public void cleanUpTask() {
        int deleted = cleanExpired();
        if (deleted > 0) {
            log.info("清理过期短信验证码 {} 条（保留 {} 小时）", deleted, retentionHours);
        }
    }

    /**
     * 删除过期验证码，返回删除条数
     */
    public int cleanExpired() {
        LocalDateTime cutoff = LocalDateTime.now().minusHours(retentionHours);
        LambdaQueryWrapper<SmsCode> wrapper = new LambdaQueryWrapper<>();
        wrapper.lt(SmsCode::getExpireTime, cutoff);
        return smsCodeMapper.delete(wrapper);
    }
}
