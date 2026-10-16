package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.dto.LoginDTO;
import com.fenglin.springboottest.dto.RegisterDTO;
import com.fenglin.springboottest.dto.ChangePasswordDTO;
import com.fenglin.springboottest.dto.RefreshTokenDTO;
import com.fenglin.springboottest.dto.ResetPasswordDTO;
import com.fenglin.springboottest.dto.UpdateProfileDTO;
import com.fenglin.springboottest.service.AuthService;
import com.fenglin.springboottest.service.CaptchaService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.util.StringUtils;

import java.util.Map;

/**
 * 认证接口（供 link-click-auth-vue 前端调用）
 *
 * <pre>
 * 1. 图形验证码：GET  /api/auth/captcha
 * 2. 注册       ：POST /api/auth/register  {username, password, confirmPassword, captchaId, captchaCode}
 *                 （手机号 phone 已改为选填，留空则不绑定手机号）
 * 3. 登录       ：POST /api/auth/login     {account, password}
 * 4. 刷新令牌   ：POST /api/auth/refresh   {refreshToken}    —— 令牌轮换，返回 accessToken + refreshToken
 * 5. 重置密码   ：POST /api/auth/reset-password {phone, code, password, confirmPassword}
 * 6. 改资料     ：PUT  /api/auth/profile        {nickname}
 * 7. 改密码     ：POST /api/auth/change-password {oldPassword, newPassword, confirmPassword}
 * 8. 短信验证码 ：GET  /api/auth/send-code       —— 已不用于注册，保留给重置密码等场景
 * </pre>
 */
@Slf4j
@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private CaptchaService captchaService;

    /** 从 Authorization 头取出不含 Bearer 前缀的 token */
    private String resolveToken(String authorization) {
        return authorization == null ? "" : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
    }

    /**
     * 登录：账号（用户名或手机号）+ 密码
     */
    @PostMapping("/login")
    public R<Map<String, Object>> login(@RequestBody @Validated LoginDTO dto) {
        log.info("收到登录请求, account={}", dto.getAccount());
        return authService.login(dto);
    }

    /**
     * 刷新令牌：用刷新令牌换一对新令牌（令牌轮换，旧刷新令牌立即作废）。
     *
     * <p>注意这个接口**不依赖 Authorization 头**——访问令牌此刻往往已经过期了，
     * 它本身就是为了找回「还有效」的身份而存在的。前端只需传刷新令牌。</p>
     */
    @PostMapping("/refresh")
    public R<Map<String, Object>> refresh(@RequestBody(required = false) RefreshTokenDTO dto) {
        String refreshToken = dto == null ? null : dto.getRefreshToken();
        if (!StringUtils.hasText(refreshToken)) {
            return R.fail(401, "缺少刷新令牌，请重新登录");
        }
        return authService.refresh(refreshToken);
    }

    /**
     * 退出登录：当前 token 立即失效
     */
    @PostMapping("/logout")
    public R<Map<String, Object>> logout(@RequestHeader(value = "Authorization", required = false) String authorization) {
        String token = resolveToken(authorization);
        if (token.isEmpty()) {
            return R.ok("已退出登录", null);
        }
        return authService.logout(token);
    }

    /**
     * 获取当前登录用户信息（请求头 Authorization: Bearer xxxxx）
     */
    @GetMapping("/profile")
    public R<Map<String, Object>> profile(@RequestHeader(value = "Authorization", required = false) String authorization) {
        String token = authorization == null ? null : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
        if (!StringUtils.hasText(token)) {
            return R.fail(401, "未携带登录凭证，请重新登录");
        }
        return authService.profile(token);
    }

    /**
     * 修改个人资料（当前只开放昵称）
     */
    @PutMapping("/profile")
    public R<Map<String, Object>> updateProfile(@RequestHeader(value = "Authorization", required = false) String authorization,
                                                @RequestBody @Validated UpdateProfileDTO dto) {
        return authService.updateProfile(resolveToken(authorization), dto);
    }

    /**
     * 修改密码：需要校验旧密码，成功后所有旧 token 失效
     */
    @PostMapping("/change-password")
    public R<Map<String, Object>> changePassword(@RequestHeader(value = "Authorization", required = false) String authorization,
                                                 @RequestBody @Validated ChangePasswordDTO dto) {
        return authService.changePassword(resolveToken(authorization), dto);
    }

    /**
     * 获取图形验证码（注册用）
     *
     * <p>返回 { captchaId, image, expireSeconds, length }，image 是 data URI，
     * 前端直接塞给 <img> 即可。校验发生在注册接口里，答案不会下发。</p>
     */
    @GetMapping("/captcha")
    public R<Map<String, Object>> captcha() {
        return R.ok("验证码已生成", captchaService.generate());
    }

    /**
     * 发送短信验证码
     *
     * @param phone 手机号
     * @param scene 场景，可选：register（注册，默认）/ reset_password（重置密码）
     * @deprecated 注册流程已改用图形验证码（GET /api/auth/captcha），
     *             此接口保留给「重置密码」等仍需短信校验的场景。
     */
    @Deprecated
    @GetMapping("/send-code")
    public R<Map<String, Object>> sendCode(@RequestParam("phone") String phone,
                                           @RequestParam(value = "scene", required = false) String scene) {
        log.info("收到验证码发送请求, phone={}, scene={}", phone, scene);
        return authService.sendCode(phone, scene);
    }

    /**
     * 重置密码
     */
    @PostMapping("/reset-password")
    public R<Map<String, Object>> resetPassword(@RequestBody @Validated ResetPasswordDTO dto) {
        log.info("收到重置密码请求, phone={}", dto.getPhone());
        return authService.resetPassword(dto);
    }

    /**
     * 注册
     */
    @PostMapping("/register")
    public R<Map<String, Object>> register(@RequestBody @Validated RegisterDTO dto) {
        log.info("收到注册请求, username={}, phone={}", dto.getUsername(), dto.getPhone());
        return authService.register(dto);
    }
}
