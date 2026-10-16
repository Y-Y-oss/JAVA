package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.enums.UserRole;
import com.fenglin.springboottest.service.AuthService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 演示「授权」（Authorization）的示例接口。
 *
 * <p>认证解决「你是谁」，授权解决「你能干什么」。这里用两个接口把 401 / 403 的差别演示出来：</p>
 *
 * <ul>
 *   <li>{@code GET /api/demo/archives}：只要登录就能看，没有凭证返回 401</li>
 *   <li>{@code GET /api/demo/archives/all}：仅管理员可看，普通用户返回 403</li>
 * </ul>
 *
 * <p>真实项目里更推荐用 Spring Security 的 {@code @PreAuthorize("hasRole('ADMIN')")} 或
 * AOP 切面来做，这里手写是为了让校验过程一目了然。</p>
 */
@Slf4j
@RestController
@RequestMapping("/api/demo")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class DemoController {

    @Autowired
    private AuthService authService;

    @GetMapping("/archives")
    public R<Map<String, Object>> archives(@RequestHeader(value = "Authorization", required = false) String authorization) {
        String token = authorization == null ? "" : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
        if (!StringUtils.hasText(token)) {
            return R.fail(401, "未携带登录凭证，请重新登录", null);
        }
        // 不传角色要求 = 只要登录即可；还会顺带校验账号状态与密码版本
        authService.checkRole(token);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("visibleTo", "登录用户");
        data.put("items", java.util.Arrays.asList(
                "2019.04 雨中私语", "2021.07 未寄出的信", "2019.12 天台上的告白"));
        return R.ok("读取到 3 条公开档案", data);
    }

    @GetMapping("/archives/all")
    public R<Map<String, Object>> allArchives(@RequestHeader(value = "Authorization", required = false) String authorization) {
        String token = authorization == null ? "" : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
        if (!StringUtils.hasText(token)) {
            return R.fail(401, "未携带登录凭证，请重新登录", null);
        }
        // 权限不足会抛 403
        authService.checkRole(token, UserRole.ADMIN.getCode());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("visibleTo", "仅管理员");
        data.put("items", java.util.Arrays.asList(
                "2019.04 雨中私语", "2021.07 未寄出的信", "2019.12 天台上的告白",
                "2020.03 被抹掉的姓名（机密）", "2022.08 时光闭锁（机密）"));
        return R.ok("读取到 5 条档案（含机密）", data);
    }
}
