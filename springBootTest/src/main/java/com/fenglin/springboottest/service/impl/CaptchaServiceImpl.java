package com.fenglin.springboottest.service.impl;

import com.fenglin.springboottest.common.BusinessException;
import com.fenglin.springboottest.service.CaptchaService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import javax.imageio.ImageIO;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Font;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.geom.Path2D;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.Collections;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;

/**
 * 图形验证码实现：服务端用 AWT 画图 + 内存存储。
 *
 * <p>为什么不落库？验证码是「两分钟就死」的短命数据，写 MySQL 只会白白制造
 * 高频写入和垃圾行（短信验证码落库是因为要按手机号做发送限频，图形码没这需求）。
 * 单机内存 Map + 定时清理足够，也避免了额外引入 Redis 的部署成本。</p>
 *
 * <p>如果以后要多实例部署，把 STORE 换成 Redis 即可，接口不用动。</p>
 */
@Slf4j
@Service
public class CaptchaServiceImpl implements CaptchaService {

    /** 去掉容易看错的 I / O / 0 / 1 */
    private static final String CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

    /** 画布尺寸按 2 倍图输出，前端用 96x34 展示，高分屏下不糊 */
    private static final int WIDTH = 192;
    private static final int HEIGHT = 68;

    /** 底色/字符配色，跟前端霓虹主题保持一致 */
    private static final Color BG_FROM = new Color(0x0D, 0x13, 0x30);
    private static final Color BG_TO = new Color(0x1D, 0x14, 0x42);
    private static final Color[] CHAR_COLORS = {
            new Color(0x7A, 0xF5, 0xF7),
            Color.WHITE,
            new Color(0xFF, 0x9A, 0xE0),
            new Color(0xB3, 0x9C, 0xFF)
    };

    /** captchaId -> 答案，一次性消费 */
    private final Map<String, Entry> store = new ConcurrentHashMap<>();

    private final SecureRandom secureRandom = new SecureRandom();

    /** 验证码有效期（秒） */
    @Value("${auth.captcha.expire-seconds:120}")
    private int expireSeconds;

    /** 字符个数 */
    @Value("${auth.captcha.length:4}")
    private int length;

    /** 内存中最多保留的验证码数量，超出即触发清理（防刷内存） */
    @Value("${auth.captcha.max-store:10000}")
    private int maxStore;

    @Override
    public Map<String, Object> generate() {
        String code = randomCode(length);
        String dataUri = "data:image/png;base64," + Base64.getEncoder().encodeToString(render(code));

        String captchaId = UUID.randomUUID().toString().replace("-", "");
        store.put(captchaId, new Entry(code, LocalDateTime.now().plusSeconds(expireSeconds)));
        evictIfNeeded();

        // 故意只写日志、不放进响应体：答案一旦随接口下发，图形验证码就形同虚设。
        // 本地联调时把 logging.level.com.fenglin.springboot 开到 debug 即可看到。
        log.debug("图形验证码已生成 captchaId={}, code={}, expireSeconds={}", captchaId, code, expireSeconds);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("captchaId", captchaId);
        data.put("image", dataUri);
        data.put("expireSeconds", expireSeconds);
        data.put("length", length);
        return data;
    }

    @Override
    public void verify(String captchaId, String input) {
        if (!StringUtils.hasText(captchaId) || !StringUtils.hasText(input)) {
            throw new BusinessException("请输入图形验证码", fieldError("请先获取图形验证码并填写"));
        }

        // 一次性消费：取出来就删掉，答错也不返还，避免被脚本反复试同一个 id
        Entry entry = store.remove(captchaId.trim());
        if (entry == null) {
            throw new BusinessException("图形验证码已失效，请点击图片重新获取", fieldError("图形验证码已失效，请点击图片刷新"));
        }
        if (entry.expireAt.isBefore(LocalDateTime.now())) {
            throw new BusinessException("图形验证码已过期，请点击图片重新获取", fieldError("图形验证码已过期，请点击图片刷新"));
        }
        if (!entry.code.equalsIgnoreCase(input.trim())) {
            throw new BusinessException("图形验证码不正确", fieldError("图形验证码不正确，已换一张"));
        }
    }

    @Override
    public int cleanExpired() {
        LocalDateTime now = LocalDateTime.now();
        int removed = 0;
        Iterator<Map.Entry<String, Entry>> it = store.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<String, Entry> e = it.next();
            if (e.getValue().expireAt.isBefore(now)) {
                it.remove();
                removed++;
            }
        }
        return removed;
    }

    @Override
    public int size() {
        return store.size();
    }

    /**
     * 每 5 分钟扫一遍过期数据。
     *
     * <p>用 fixedDelay 而不是 cron：单机内存表的清理没有「必须几点跑」的语义，
     * 固定间隔更平稳，也不会和 {@link com.fenglin.springboottest.common.SmsCodeCleaner} 的整点任务撞车。</p>
     */
    @Scheduled(initialDelay = 60_000L, fixedDelay = 300_000L)
    public void scheduledClean() {
        int removed = cleanExpired();
        if (removed > 0) {
            log.debug("清理过期图形验证码 {} 条，当前保有 {} 条", removed, store.size());
        }
        evictIfNeeded();
    }

    /** 超过上限就先清过期，仍超标则按插入顺序丢弃最旧的，保证内存不会无限膨胀 */
    private void evictIfNeeded() {
        if (store.size() <= maxStore) {
            return;
        }
        cleanExpired();
        Iterator<String> it = store.keySet().iterator();
        while (store.size() > maxStore && it.hasNext()) {
            it.next();
            it.remove();
        }
        log.warn("图形验证码内存已达上限 {}，已淘汰多余条目，当前 {} 条", maxStore, store.size());
    }

    private static Map<String, String> fieldError(String message) {
        return Collections.singletonMap("captchaCode", message);
    }

    private String randomCode(int len) {
        StringBuilder sb = new StringBuilder(len);
        for (int i = 0; i < len; i++) {
            sb.append(CHARS.charAt(secureRandom.nextInt(CHARS.length())));
        }
        return sb.toString();
    }

    /**
     * 画图：渐变色底 + 干扰曲线 + 噪点 + 随机旋转的字符
     */
    private byte[] render(String code) {
        BufferedImage image = new BufferedImage(WIDTH, HEIGHT, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = image.createGraphics();
        try {
            g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);

            // 底色：左上到右下的线性渐变
            g.setPaint(new java.awt.GradientPaint(0, 0, BG_FROM, WIDTH, HEIGHT, BG_TO));
            g.fillRect(0, 0, WIDTH, HEIGHT);

            // 干扰曲线
            for (int i = 0; i < 6; i++) {
                Path2D.Float curve = new Path2D.Float();
                curve.moveTo(rand(0, WIDTH), rand(0, HEIGHT));
                curve.quadTo(rand(0, WIDTH), rand(0, HEIGHT), rand(0, WIDTH), rand(0, HEIGHT));
                g.setColor(noiseColor(0.20f, 0.45f));
                g.setStroke(new BasicStroke(randFloat(1f, 2.2f)));
                g.draw(curve);
            }

            // 噪点
            for (int i = 0; i < 80; i++) {
                g.setColor(noiseColor(0.15f, 0.45f));
                int r = rand(1, 3);
                g.fillOval(rand(0, WIDTH), rand(0, HEIGHT), r, r);
            }

            // 字符
            int len = code.length();
            float cell = (float) (WIDTH - 14) / len;
            int fontSize = Math.max(20, Math.round(HEIGHT * 0.52f));
            for (int i = 0; i < len; i++) {
                String ch = String.valueOf(code.charAt(i));
                Graphics2D gc = (Graphics2D) g.create();
                try {
                    float x = 7 + cell * i + cell / 2;
                    float y = HEIGHT / 2f + randFloat(-3f, 3f);
                    gc.translate(x, y);
                    gc.rotate(Math.toRadians(rand(-18, 18)));
                    gc.setFont(new Font(Font.SANS_SERIF, Font.BOLD, fontSize + rand(-2, 2)));
                    gc.setColor(CHAR_COLORS[rand(0, CHAR_COLORS.length - 1)]);
                    // 轻微发光，和前端的霓虹感对上
                    gc.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING, RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
                    java.awt.FontMetrics fm = gc.getFontMetrics();
                    gc.drawString(ch, -fm.stringWidth(ch) / 2f, fm.getAscent() / 2f - 1);
                } finally {
                    gc.dispose();
                }
            }
        } finally {
            g.dispose();
        }

        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            ImageIO.write(image, "png", out);
            return out.toByteArray();
        } catch (IOException e) {
            log.error("图形验证码渲染失败", e);
            throw new BusinessException("验证码生成失败，请稍后重试");
        }
    }

    private static Color noiseColor(float minAlpha, float maxAlpha) {
        return new Color(rand(60, 200), rand(140, 250), rand(200, 255),
                Math.round(randFloat(minAlpha, maxAlpha) * 255));
    }

    private static int rand(int min, int max) {
        return ThreadLocalRandom.current().nextInt(min, max + 1);
    }

    private static float randFloat(float min, float max) {
        return min + ThreadLocalRandom.current().nextFloat() * (max - min);
    }

    /** 一条验证码记录 */
    private static final class Entry {
        private final String code;
        private final LocalDateTime expireAt;

        private Entry(String code, LocalDateTime expireAt) {
            this.code = code;
            this.expireAt = expireAt;
        }
    }
}
