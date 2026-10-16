package com.fenglin.springboottest.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.common.BusinessException;
import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.common.TokenBlacklist;
import com.fenglin.springboottest.dto.ChangePasswordDTO;
import com.fenglin.springboottest.dto.LoginDTO;
import com.fenglin.springboottest.dto.RegisterDTO;
import com.fenglin.springboottest.dto.ResetPasswordDTO;
import com.fenglin.springboottest.dto.UpdateProfileDTO;
import com.fenglin.springboottest.entity.RefreshToken;
import com.fenglin.springboottest.entity.SmsCode;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.enums.UserRole;
import com.fenglin.springboottest.mapper.RefreshTokenMapper;
import com.fenglin.springboottest.mapper.SmsCodeMapper;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.service.AuthService;
import com.fenglin.springboottest.service.CaptchaService;
import com.fenglin.springboottest.util.JwtUtil;
import com.fenglin.springboottest.util.OpaqueTokenUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.util.ObjectUtils;
import org.springframework.util.StringUtils;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.UUID;

/**
 * 认证业务实现：验证码发放与校验、用户注册、双令牌签发与轮换
 */
@Slf4j
@Service
public class AuthServiceImpl implements AuthService {

    private static final String PHONE_REGEX = "^1[3-9]\\d{9}$";

    /** refresh 令牌吊销状态：0-有效，1-已轮换，2-已吊销 */
    private static final int REVOKED_NONE = 0;
    private static final int REVOKED_ROTATED = 1;
    private static final int REVOKED_REVOKED = 2;

    /** 验证码场景：注册 */
    public static final String SCENE_REGISTER = "register";
    /** 验证码场景：重置密码 */
    public static final String SCENE_RESET_PASSWORD = "reset_password";

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private SmsCodeMapper smsCodeMapper;

    @Autowired
    private CaptchaService captchaService;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private TokenBlacklist tokenBlacklist;

    @Autowired
    private RefreshTokenMapper refreshTokenMapper;

    /** 刷新令牌有效期（秒），默认 15 天 */
    @Value("${jwt.refresh-expire-seconds:1296000}")
    private long refreshExpireSeconds;

    /** 验证码有效期（秒） */
    @Value("${auth.sms.code-expire-seconds:300}")
    private int codeExpireSeconds;

    /** 两次发送验证码的最小间隔（秒） */
    @Value("${auth.sms.resend-interval-seconds:60}")
    private int resendIntervalSeconds;

    /** 验证码场景 */
    @Value("${auth.sms.scene:register}")
    private String scene;

    /** 演示模式：true 时把验证码返回给前端，方便本地联调 */
    @Value("${auth.sms.debug:true}")
    private boolean debug;

    @Override
    public R<Map<String, Object>> sendCode(String phone, String scene) {
        if (!StringUtils.hasText(phone) || !phone.matches(PHONE_REGEX)) {
            throw new BusinessException("请输入正确的 11 位手机号");
        }
        // 场景不传时走默认场景，未知场景直接拒绝，避免绕过业务限制
        String finalScene = resolveScene(scene);

        // 发送频率控制：同一场景、resendIntervalSeconds 秒内不允许重复发送
        LocalDateTime minCreateTime = LocalDateTime.now().minusSeconds(resendIntervalSeconds);
        List<SmsCode> recent = smsCodeMapper.selectRecent(phone, finalScene, minCreateTime);
        if (!ObjectUtils.isEmpty(recent)) {
            throw new BusinessException("验证码发送过于频繁，请 " + resendIntervalSeconds + " 秒后再试");
        }

        String code = generateCode();
        // 清掉该手机号在该场景下的历史验证码，保证最新一条一定可用
        smsCodeMapper.deleteByPhoneAndScene(phone, finalScene);

        SmsCode smsCode = new SmsCode();
        smsCode.setPhone(phone);
        smsCode.setCode(code);
        smsCode.setScene(finalScene);
        smsCode.setExpireTime(LocalDateTime.now().plusSeconds(codeExpireSeconds));
        smsCode.setConsumed(0);
        smsCodeMapper.insert(smsCode);

        log.info("【演示模式】短信验证码已生成 phone={}, scene={}, code={}, expireSeconds={}",
                phone, finalScene, code, codeExpireSeconds);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("phone", phone);
        data.put("scene", finalScene);
        data.put("expireSeconds", codeExpireSeconds);
        data.put("resendSeconds", resendIntervalSeconds);
        if (debug) {
            data.put("code", code);
        }
        return R.ok("验证码已发送，请注意查收", data);
    }

    @Override
    public R<Map<String, Object>> register(RegisterDTO dto) {
        String username = dto.getUsername();
        // 手机号选填：留空就存 NULL，不参与唯一性校验
        String phone = StringUtils.hasText(dto.getPhone()) ? dto.getPhone().trim() : null;
        String password = dto.getPassword();

        // 二次确认密码
        if (!StringUtils.hasText(dto.getConfirmPassword()) || !dto.getConfirmPassword().equals(password)) {
            throw new BusinessException("两次输入的密码不一致",
                    Collections.singletonMap("pwd2", "两次密码不一致"));
        }

        // 图形验证码校验（服务端校验，一次性消费；答错/过期都会抛业务异常）
        captchaService.verify(dto.getCaptchaId(), dto.getCaptchaCode());

        // 用户名是否已被占用
        LambdaQueryWrapper<User> usernameWrapper = new LambdaQueryWrapper<>();
        usernameWrapper.eq(User::getUsername, username);
        if (userMapper.selectCount(usernameWrapper) > 0) {
            throw new BusinessException("该用户名已被占用",
                    Collections.singletonMap("username", "该用户名已被占用"));
        }
        // 只有在填了手机号时才校验手机号是否已注册
        if (phone != null && userMapper.selectByPhone(phone) != null) {
            throw new BusinessException("该手机号已注册，请直接登录",
                    Collections.singletonMap("phone", "该手机号已注册，请直接登录"));
        }

        // 写入用户（密码使用 BCrypt 加密，绝不存明文）
        User user = new User();
        user.setUsername(username);
        user.setPhone(phone);
        user.setPassword(passwordEncoder.encode(password));
        user.setNickname(username);
        user.setRole(UserRole.USER.getCode());
        user.setStatus(1);
        userMapper.insert(user);

        log.info("注册成功 userId={}, username={}, phone={}", user.getId(), username, phone);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", user.getId());
        data.put("username", user.getUsername());
        data.put("phone", user.getPhone());
        data.put("nickname", user.getNickname());
        return R.ok("注册成功，欢迎成为时光代理人", data);
    }

    @Override
    public R<Map<String, Object>> resetPassword(ResetPasswordDTO dto) {
        String phone = dto.getPhone();
        String code = dto.getCode();
        String password = dto.getPassword();

        if (!StringUtils.hasText(phone) || !phone.matches(PHONE_REGEX)) {
            throw new BusinessException("请输入正确的 11 位手机号");
        }
        // 二次确认密码
        if (!StringUtils.hasText(dto.getConfirmPassword()) || !dto.getConfirmPassword().equals(password)) {
            throw new BusinessException("两次输入的密码不一致",
                    Collections.singletonMap("pwd2", "两次密码不一致"));
        }
        // 新密码不能与旧密码相同
        User exist = userMapper.selectByPhone(phone);
        if (exist == null) {
            throw new BusinessException("该手机号尚未注册，请前往注册");
        }
        if (passwordEncoder.matches(password, exist.getPassword())) {
            throw new BusinessException("新密码不能与当前密码相同，请换一个");
        }

        // 校验重置验证码（校验通过即失效）
        consumeCode(phone, SCENE_RESET_PASSWORD, code);

        // 与「修改密码」保持一致：提升密码版本号，让该手机号上所有已签发的旧 token 立即失效，
        // 并吊销全部刷新令牌，避免攻击者持有的会话在用户重置密码后仍能继续用到自然过期为止
        int nextVersion = (exist.getPwdVersion() == null ? 1 : exist.getPwdVersion()) + 1;
        User update = new User();
        update.setId(exist.getId());
        update.setPassword(passwordEncoder.encode(password));
        update.setPwdVersion(nextVersion);
        userMapper.updateById(update);
        revokeAllRefreshTokens(exist.getId(), "password-reset");

        log.info("重置密码成功 userId={}, phone={}, pwdVersion -> {}", exist.getId(), phone, nextVersion);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", exist.getId());
        data.put("username", exist.getUsername());
        data.put("phone", exist.getPhone());
        return R.ok("密码已重置，请使用新密码登录", data);
    }

    @Override
    public R<Map<String, Object>> login(LoginDTO dto) {
        String account = dto.getAccount() == null ? "" : dto.getAccount().trim();
        String password = dto.getPassword();
        if (!StringUtils.hasText(account) || !StringUtils.hasText(password)) {
            throw new BusinessException("请输入手机号或账号");
        }

        // 先按用户名查，再按手机号查
        User user = userMapper.selectByUsername(account);
        if (user == null) {
            user = userMapper.selectByPhone(account);
        }
        if (user == null || user.getStatus() != null && user.getStatus() == 0) {
            // 不区分“账号不存在”和“密码错误”，避免账号枚举
            throw new BusinessException("账号或密码错误");
        }
        if (!passwordEncoder.matches(password, user.getPassword())) {
            throw new BusinessException("账号或密码错误");
        }

        // 记录最近一次登录时间
        User loginRecord = new User();
        loginRecord.setId(user.getId());
        loginRecord.setLastLoginTime(LocalDateTime.now());
        userMapper.updateById(loginRecord);

        log.info("登录成功 userId={}, username={}", user.getId(), user.getUsername());

        Map<String, Object> data = issueTokenPair(user);
        data.put("id", user.getId());
        data.put("username", user.getUsername());
        data.put("phone", user.getPhone());
        data.put("nickname", user.getNickname());
        data.put("role", user.getRole());
        return R.ok("登录成功，正在穿越时光…", data);
    }

    /**
     * 为指定用户签发「访问令牌 + 刷新令牌」一对凭证。
     *
     * <p>刷新令牌在库中登记一条记录（只存 SHA-256 摘要），并分配一个令牌族 familyId。
     * 后续每次续期都会在当前族内轮换，族内任一环出现重放则整族作废。</p>
     */
    private Map<String, Object> issueTokenPair(User user) {
        String accessToken = jwtUtil.generateToken(user);
        String refreshToken = OpaqueTokenUtil.generate();
        String familyId = UUID.randomUUID().toString();
        LocalDateTime expiresAt = LocalDateTime.now().plusSeconds(refreshExpireSeconds);

        RefreshToken record = new RefreshToken();
        record.setUserId(user.getId());
        record.setTokenHash(OpaqueTokenUtil.sha256Hex(refreshToken));
        record.setFamilyId(familyId);
        record.setExpiresAt(expiresAt);
        record.setRevoked(REVOKED_NONE);
        refreshTokenMapper.insert(record);

        log.info("签发令牌对 userId={}, family={}, refreshExpiresAt={}", user.getId(), familyId, expiresAt);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("accessToken", accessToken);
        data.put("refreshToken", refreshToken);
        data.putAll(buildTokenMeta(user));
        return data;
    }

    /** 令牌元信息：类型与有效期，前端据此决定何时提前续期 */
    private Map<String, Object> buildTokenMeta(User user) {
        Map<String, Object> meta = new LinkedHashMap<>();
        meta.put("tokenType", "Bearer");
        meta.put("expiresIn", jwtUtil.getExpireSeconds());
        meta.put("refreshExpiresIn", refreshExpireSeconds);
        meta.put("id", user.getId());
        return meta;
    }

    @Override
    public R<Map<String, Object>> profile(String token) {
        User user = requireLoginUser(token);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", user.getId());
        data.put("username", user.getUsername());
        data.put("phone", user.getPhone());
        data.put("nickname", user.getNickname());
        data.put("role", user.getRole());
        data.put("lastLoginTime", user.getLastLoginTime());
        return R.ok(data);
    }

    @Override
    public void checkRole(String token, String... requiredRoles) {
        // 这一步会顺带完成「是否已登录 / 账号是否可用 / 密码版本是否落后」的校验
        User user = requireLoginUser(token);
        UserRole role = UserRole.of(user.getRole());
        if (!role.matches(requiredRoles)) {
            log.warn("权限不足 userId={}, role={}, required={}", user.getId(), role.getCode(), Arrays.toString(requiredRoles));
            throw new BusinessException(403,
                    "权限不足，该操作需要「" + UserRole.of(requiredRoles[0]).getLabel() + "」角色");
        }
    }

    @Override
    public R<Map<String, Object>> refresh(String refreshToken) {
        String hash = OpaqueTokenUtil.sha256Hex(refreshToken);
        RefreshToken old = refreshTokenMapper.selectByHash(hash);
        if (old == null) {
            // 摘要在库里找不到：要么已经过期被清理，要么根本没签发过
            throw new BusinessException(401, "刷新令牌无效或已过期，请重新登录");
        }

        // —— 关键：同一枚刷新令牌被用了第二次就是重放 ——
        // 正常轮换会把旧记录标记为「已轮换」，此刻它还躺在库里且状态为有效，只可能是同一枚令牌被重复提交。
        if (old.getRevoked() != null && old.getRevoked() != REVOKED_NONE) {
            log.warn("检测到刷新令牌重放 userId={}, family={}, revoked={}",
                    old.getUserId(), old.getFamilyId(), old.getRevoked());
            // 整族作废：本次泄漏的令牌族后续全部无法续期，逼迫用户重新登录
            refreshTokenMapper.revokeFamily(old.getFamilyId(), REVOKED_REVOKED, "replay");
            throw new BusinessException(401, "检测到登录凭证被重复使用，已撤销该账号的全部登录状态，请重新登录");
        }

        LocalDateTime now = LocalDateTime.now();
        if (old.getExpiresAt() == null || old.getExpiresAt().isBefore(now)) {
            refreshTokenMapper.revokeFamily(old.getFamilyId(), REVOKED_REVOKED, "expired-on-use");
            throw new BusinessException(401, "刷新令牌已过期，请重新登录");
        }

        User user = userMapper.selectById(old.getUserId());
        if (user == null || user.getStatus() == null || user.getStatus() == 0) {
            throw new BusinessException(401, "用户不存在或账号已被禁用");
        }

        // —— 令牌轮换（rotation）：作废旧记录，签出新的一对，同族延续 ——
        String newRefreshToken = OpaqueTokenUtil.generate();
        String newHash = OpaqueTokenUtil.sha256Hex(newRefreshToken);
        LocalDateTime newExpiresAt = now.plusSeconds(refreshExpireSeconds);

        RefreshToken rotated = new RefreshToken();
        rotated.setUserId(user.getId());
        rotated.setTokenHash(newHash);
        rotated.setFamilyId(old.getFamilyId());
        rotated.setExpiresAt(newExpiresAt);
        rotated.setRevoked(REVOKED_NONE);
        refreshTokenMapper.insert(rotated);

        old.setRevoked(REVOKED_ROTATED);
        old.setRevokedReason("rotate");
        old.setReplacedBy(newHash);
        refreshTokenMapper.updateById(old);

        log.info("刷新令牌轮换成功 userId={}, family={}, 旧记录 id={} -> 新记录 id={}",
                user.getId(), old.getFamilyId(), old.getId(), rotated.getId());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("accessToken", jwtUtil.generateToken(user));
        data.put("refreshToken", newRefreshToken);
        data.putAll(buildTokenMeta(user));
        return R.ok("登录状态已续期", data);
    }

    @Override
    public R<Map<String, Object>> logout(String token) {
        long expiresAtMillis;
        try {
            expiresAtMillis = jwtUtil.getExpirationMillis(token);
        } catch (Exception e) {
            throw new BusinessException("登录凭证无效");
        }
        tokenBlacklist.add(token, expiresAtMillis);

        // 顺便吊销该用户在其他设备上的刷新令牌：token 里带的用户 id 足够定位，
        // 不必让前端再传一次刷新令牌，避免「拿令牌换令牌」的多传一参。
        try {
            Long userId = jwtUtil.getUserId(token);
            int affected = refreshTokenMapper.revokeByUserId(userId, REVOKED_REVOKED, "logout");
            if (affected > 0) {
                log.info("用户 {} 登出，吊销了 {} 个刷新令牌", userId, affected);
            }
        } catch (Exception e) {
            // 令牌已过期无法解析用户 id 时，仅让当前 token 失效即可
            log.debug("解析登出令牌的用户 id 失败，跳过刷新令牌吊销：{}", e.getMessage());
        }

        log.info("用户已登出，token 加入黑名单，有效期至 {}", expiresAtMillis);
        return R.ok("已退出登录", null);
    }

    @Override
    public R<Map<String, Object>> updateProfile(String token, UpdateProfileDTO dto) {
        User user = requireLoginUser(token);

        String nickname = dto.getNickname() == null ? "" : dto.getNickname().trim();
        if (!StringUtils.hasText(nickname)) {
            throw new BusinessException("昵称不能为空");
        }

        User update = new User();
        update.setId(user.getId());
        update.setNickname(nickname);
        userMapper.updateById(update);

        log.info("更新资料成功 userId={}, nickname={}", user.getId(), nickname);
        return R.ok("资料已更新", buildUserMap(userMapper.selectById(user.getId())));
    }

    @Override
    public R<Map<String, Object>> changePassword(String token, ChangePasswordDTO dto) {
        User user = requireLoginUser(token);

        if (!StringUtils.hasText(dto.getConfirmPassword()) || !dto.getConfirmPassword().equals(dto.getNewPassword())) {
            throw new BusinessException("两次输入的密码不一致",
                    Collections.singletonMap("confirmPassword", "两次密码不一致"));
        }
        // 当前密码错误时不泄露账号是否存在，统一提示
        if (!passwordEncoder.matches(dto.getOldPassword(), user.getPassword())) {
            throw new BusinessException("当前密码错误");
        }
        if (passwordEncoder.matches(dto.getNewPassword(), user.getPassword())) {
            throw new BusinessException("新密码不能与当前密码相同，请换一个");
        }

        int nextVersion = (user.getPwdVersion() == null ? 1 : user.getPwdVersion()) + 1;
        User update = new User();
        update.setId(user.getId());
        update.setPassword(passwordEncoder.encode(dto.getNewPassword()));
        update.setPwdVersion(nextVersion);
        userMapper.updateById(update);

        // 旧 token 里携带的密码版本号已落后，之后所有请求都会被引擎拒绝；
        // 刷新令牌也一并吊销，否则攻击者可以用旧的 refresh 换出新 token 绕回来
        revokeAllRefreshTokens(user.getId(), "password-changed");
        log.info("修改密码成功 userId={}, pwdVersion {} -> {}", user.getId(), user.getPwdVersion(), nextVersion);
        return R.ok("密码已修改，其他设备的登录状态已失效，请用新密码重新登录", null);
    }

    /**
     * 吊销某用户的全部刷新令牌（改密 / 重置密码时调用）
     */
    private void revokeAllRefreshTokens(Long userId, String reason) {
        int affected = refreshTokenMapper.revokeByUserId(userId, REVOKED_REVOKED, reason);
        if (affected > 0) {
            log.info("吊销用户 {} 的 {} 个刷新令牌，原因={}", userId, affected, reason);
        }
    }

    /**
     * 解析 token 并取出当前登录用户；不通过则抛出异常。
     *
     * <p>三道关卡：是否已退出登录、用户是否仍存在/未被禁用、密码版本号是否与 token 一致。
     * 第三道是「修改密码后强制所有设备下线」的关键——密码一改，版本号 +1，
     * 所有旧 token 携带的 pv 就都落后了。</p>
     */
    private User requireLoginUser(String token) {
        if (tokenBlacklist.isBlacklisted(token)) {
            throw new BusinessException("登录状态已失效，请重新登录");
        }
        Long userId;
        int tokenPwdVersion;
        try {
            userId = jwtUtil.getUserId(token);
            tokenPwdVersion = jwtUtil.getPwdVersion(token);
        } catch (Exception e) {
            // 过期 / 签名错误 / 被篡改，统一按 401 处理，前端据此清掉本地凭证
            throw new BusinessException(401, "登录已过期或凭证无效，请重新登录");
        }

        User user = userMapper.selectById(userId);
        if (user == null || user.getStatus() != null && user.getStatus() == 0) {
            throw new BusinessException("用户不存在或账号已被禁用");
        }
        int currentVersion = user.getPwdVersion() == null ? 1 : user.getPwdVersion();
        if (currentVersion != tokenPwdVersion) {
            throw new BusinessException("登录状态已失效（密码已变更），请用新密码重新登录");
        }
        return user;
    }

    /** 统一的用户信息返回结构 */
    private Map<String, Object> buildUserMap(User user) {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", user.getId());
        data.put("username", user.getUsername());
        data.put("phone", user.getPhone());
        data.put("nickname", user.getNickname());
        data.put("role", user.getRole());
        data.put("lastLoginTime", user.getLastLoginTime());
        return data;
    }

    /**
     * 校验并消费指定场景下的验证码（一次性）。
     *
     * @param phone 手机号
     * @param scene 验证码场景
     * @param code  用户填写的验证码
     */
    private void consumeCode(String phone, String scene, String code) {
        LocalDateTime minCreateTime = LocalDateTime.now().minusSeconds(codeExpireSeconds);
        SmsCode smsCode = smsCodeMapper.selectLatestValid(phone, scene, minCreateTime, 0);
        if (ObjectUtils.isEmpty(smsCode)) {
            throw new BusinessException("验证码不存在或已过期，请重新获取");
        }
        if (!MessageDigest.isEqual(smsCode.getCode().getBytes(StandardCharsets.UTF_8),
                code.getBytes(StandardCharsets.UTF_8))) {
            throw new BusinessException("验证码错误，请重新输入");
        }
        // 标记验证码已使用（带 consumed=0 条件，避免并发重复提交）
        SmsCode consumedFlag = new SmsCode();
        consumedFlag.setConsumed(1);
        LambdaQueryWrapper<SmsCode> consumeWrapper = new LambdaQueryWrapper<>();
        consumeWrapper.eq(SmsCode::getId, smsCode.getId())
                .eq(SmsCode::getConsumed, 0);
        smsCodeMapper.update(consumedFlag, consumeWrapper);
    }

    /**
     * 解析验证码场景：为空时用配置默认值，不在白名单内的场景直接拒绝
     */
    private String resolveScene(String scene) {
        if (!StringUtils.hasText(scene)) {
            return this.scene;
        }
        if (!SCENE_REGISTER.equals(scene) && !SCENE_RESET_PASSWORD.equals(scene)) {
            throw new BusinessException("不支持的验证码场景");
        }
        return scene;
    }

    /** 生成 6 位数字验证码 */
    private String generateCode() {
        Random random = new Random();
        StringBuilder sb = new StringBuilder(6);
        for (int i = 0; i < 6; i++) {
            sb.append(random.nextInt(10));
        }
        return sb.toString();
    }
}
