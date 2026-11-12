package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.common.BusinessException;
import com.fenglin.springboottest.dto.LoginDTO;
import com.fenglin.springboottest.dto.RegisterDTO;
import com.fenglin.springboottest.dto.ChangePasswordDTO;
import com.fenglin.springboottest.dto.RefreshTokenDTO;
import com.fenglin.springboottest.dto.ResetPasswordDTO;
import com.fenglin.springboottest.dto.UpdateProfileDTO;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.service.AuthService;
import com.fenglin.springboottest.service.CaptchaService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
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
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

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

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private com.fenglin.springboottest.util.JwtUtil jwtUtil;

    /** 上传根目录（头像存到其 avatars/ 子目录），与档案封面共用同一配置 */
    @Value("${file.upload-dir:./uploads}")
    private String uploadDir;

    /** 从 Authorization 头取出不含 Bearer 前缀的 token */
    private String resolveToken(String authorization) {
        return authorization == null ? "" : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
    }

    /** 校验已登录并返回当前用户实体 */
    private User requireUser(String authorization) {
        String token = resolveToken(authorization);
        if (!StringUtils.hasText(token)) {
            throw new BusinessException(401, "未携带登录凭证，请重新登录");
        }
        authService.checkRole(token);
        User user = userMapper.selectById(jwtUtil.getUserId(token));
        if (user == null) {
            throw new BusinessException(401, "登录状态异常，请重新登录");
        }
        return user;
    }

    /**
     * 上传头像（需登录）：multipart/form-data，字段名 file，仅限图片且 ≤5MB。
     * 保存到上传目录 avatars/ 子目录，UUID 重命名，写回 lc_user.avatar，
     * 返回可访问的相对 URL（如 /uploads/avatars/xxx.png）。
     */
    @PostMapping(value = "/avatar", consumes = "multipart/form-data")
    public R<Map<String, Object>> uploadAvatar(@RequestHeader(value = "Authorization", required = false) String authorization,
                                               @RequestParam("file") MultipartFile file) {
        User user = requireUser(authorization);
        if (file == null || file.isEmpty()) {
            throw new BusinessException("请选择要上传的图片");
        }
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            throw new BusinessException("仅支持上传图片文件（png/jpg/webp/gif）");
        }
        if (file.getSize() > 5 * 1024 * 1024) {
            throw new BusinessException("图片不能超过 5MB");
        }

        // 真实图片校验：读文件头魔数，防止伪造 content-type（与档案封面同一套规则）
        try (InputStream in = file.getInputStream()) {
            byte[] head = new byte[12];
            int n = in.read(head);
            boolean ok = false;
            if (n >= 4) {
                ok = (head[0] == (byte) 0x89 && head[1] == 0x50 && head[2] == 0x4E && head[3] == 0x47)
                        || ((head[0] & 0xFF) == 0xFF && head[1] == (byte) 0xD8 && head[2] == (byte) 0xFF)
                        || (head[0] == 0x47 && head[1] == 0x49 && head[2] == 0x46);
            }
            if (!ok && n >= 12) {
                ok = head[0] == 0x52 && head[1] == 0x49 && head[2] == 0x46 && head[3] == 0x46
                        && head[8] == 0x57 && head[9] == 0x45 && head[10] == 0x42 && head[11] == 0x50;
            }
            if (!ok) {
                throw new BusinessException("文件不是有效的图片（支持 png/jpg/webp/gif）");
            }
        } catch (IOException e) {
            throw new BusinessException("文件读取失败：" + e.getMessage());
        }

        String original = file.getOriginalFilename();
        String ext = "png";
        if (original != null && original.contains(".")) {
            String e = original.substring(original.lastIndexOf('.') + 1).toLowerCase();
            if (Arrays.asList("png", "jpg", "jpeg", "webp", "gif").contains(e)) {
                ext = e;
            }
        }
        String filename = UUID.randomUUID().toString().replace("-", "") + "." + ext;

        File dir = new File(new File(uploadDir).getAbsoluteFile(), "avatars");
        if (!dir.exists() && !dir.mkdirs()) {
            throw new BusinessException("上传目录创建失败，请联系管理员");
        }
        File dest = new File(dir, filename);
        try {
            // 关键：transferTo 必须传绝对路径，否则 Tomcat 会把相对路径解析到它的临时工作目录
            file.transferTo(dest);
        } catch (IOException e) {
            throw new BusinessException("文件保存失败：" + e.getMessage());
        }

        String url = "/uploads/avatars/" + filename;
        user.setAvatar(url);
        userMapper.updateById(user);
        log.info("头像已更新 userId={}, url={}", user.getId(), url);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("url", url);
        return R.ok("头像已更新", data);
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
