package com.fenglin.springboottest.service;

import java.util.Map;

/**
 * 图形验证码服务
 *
 * <p>服务端生成图片、服务端校验答案，前端只拿到图片和一次性 captchaId。
 * 相比「前端 canvas 自己画自己比对」，这种做法才能真正挡住脚本批量注册。</p>
 */
public interface CaptchaService {

    /**
     * 生成一张图形验证码
     *
     * @return { captchaId, image(data URI), expireSeconds, length }
     */
    Map<String, Object> generate();

    /**
     * 校验图形验证码，校验后立即失效（无论对错都作废，防暴力重试）
     *
     * @param captchaId 生成时下发的标识
     * @param input     用户输入
     * @throws com.fenglin.springboottest.common.BusinessException 校验不通过
     */
    void verify(String captchaId, String input);

    /**
     * 清理内存中已过期的验证码，返回清理条数
     */
    int cleanExpired();

    /**
     * 当前内存中保有的验证码数量（监控 / 排查用）
     */
    int size();
}
