package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.common.BusinessException;
import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.enums.UserRole;
import com.fenglin.springboottest.mapper.RefreshTokenMapper;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.service.AuthService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理后台接口（仅 ADMIN 角色可访问，页面见 static/admin/index.html）
 *
 * <pre>
 * 1. 统计概览：GET    /api/admin/stats
 * 2. 用户列表：GET    /api/admin/users?keyword=&amp;status=&amp;page=1&amp;size=10
 * 3. 启用/禁用：PUT   /api/admin/users/{id}/status     {status: 0|1}
 * 4. 角色调整：PUT    /api/admin/users/{id}/role       {role: "user"|"admin"}
 * 5. 重置密码：PUT    /api/admin/users/{id}/password   {password}
 * 6. 删除用户：DELETE /api/admin/users/{id}
 * </pre>
 *
 * <p>沿用项目里「Controller 手动解析 Authorization 头 + authService.checkRole」的鉴权风格，
 * 与 DemoController 保持一致。管理员不能禁用/降级/删除自己，避免把自己锁在门外。</p>
 */
@Slf4j
@RestController
@RequestMapping("/api/admin")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class AdminUserController {

    /** 刷新令牌吊销原因码：主动吊销（与 AuthServiceImpl.REVOKED_REVOKED 一致） */
    private static final int REVOKED_REVOKED = 2;

    @Autowired
    private AuthService authService;

    @Autowired
    private UserMapper userMapper;

    @Autowired
    private RefreshTokenMapper refreshTokenMapper;

    /** 从 Authorization 头取出不含 Bearer 前缀的 token */
    private String resolveToken(String authorization) {
        return authorization == null ? "" : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
    }

    /** 校验是管理员（基于 permission 字段，0-管理员权限），返回管理员实体 */
    private User requireAdmin(String authorization) {
        String token = resolveToken(authorization);
        return authService.requireAdmin(token);
    }

    // ============================ 1. 统计概览 ============================

    @GetMapping("/stats")
    public R<Map<String, Object>> stats(@RequestHeader(value = "Authorization", required = false) String authorization) {
        requireAdmin(authorization);

        LocalDateTime todayStart = LocalDate.now().atStartOfDay();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total", userMapper.selectCount(null));
        data.put("active", userMapper.selectCount(new LambdaQueryWrapper<User>().eq(User::getStatus, 1)));
        data.put("disabled", userMapper.selectCount(new LambdaQueryWrapper<User>().eq(User::getStatus, 0)));
        data.put("admins", userMapper.selectCount(new LambdaQueryWrapper<User>().eq(User::getPermission, 0)));
        data.put("todayNew", userMapper.selectCount(new LambdaQueryWrapper<User>().ge(User::getCreateTime, todayStart)));
        return R.ok("查询成功", data);
    }

    // ============================ 2. 用户列表 ============================

    /**
     * 分页查询用户（按创建时间倒序，密码字段不返回）
     *
     * @param keyword 模糊匹配 用户名 / 昵称 / 手机号
     * @param status  1-正常，0-禁用，不传查全部
     */
    @GetMapping("/users")
    public R<Map<String, Object>> users(@RequestHeader(value = "Authorization", required = false) String authorization,
                                        @RequestParam(value = "keyword", required = false) String keyword,
                                        @RequestParam(value = "status", required = false) Integer status,
                                        @RequestParam(value = "page", defaultValue = "1") long page,
                                        @RequestParam(value = "size", defaultValue = "10") long size) {
        requireAdmin(authorization);

        if (page < 1) page = 1;
        if (size < 1 || size > 50) size = 10;

        LambdaQueryWrapper<User> wrapper = new LambdaQueryWrapper<>();
        if (StringUtils.hasText(keyword)) {
            String kw = keyword.trim();
            wrapper.and(w -> w.like(User::getUsername, kw)
                    .or().like(User::getNickname, kw)
                    .or().like(User::getPhone, kw));
        }
        if (status != null) {
            wrapper.eq(User::getStatus, status);
        }
        wrapper.orderByDesc(User::getId);

        long total = userMapper.selectCount(wrapper);
        // 未引入分页插件，用 LIMIT 手工分页（管理端数据量小，够用且行为可控）
        wrapper.last("LIMIT " + ((page - 1) * size) + ", " + size);
        List<User> users = userMapper.selectList(wrapper);

        List<Map<String, Object>> records = new ArrayList<>();
        for (User u : users) {
            records.add(toSummary(u));
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total", total);
        data.put("page", page);
        data.put("size", size);
        data.put("records", records);
        return R.ok("查询成功", data);
    }

    // ============================ 3. 启用 / 禁用 ============================

    @PutMapping("/users/{id}/status")
    public R<Map<String, Object>> updateStatus(@RequestHeader(value = "Authorization", required = false) String authorization,
                                               @PathVariable("id") Long id,
                                               @RequestBody Map<String, Integer> body) {
        User admin = requireAdmin(authorization);

        Integer status = body.get("status");
        if (status == null || (status != 0 && status != 1)) {
            throw new BusinessException("status 只能为 0（禁用）或 1（启用）");
        }
        User user = requireUser(id);
        if (user.getId().equals(admin.getId())) {
            throw new BusinessException("不能对自己的账号执行启用/禁用操作");
        }

        User update = new User();
        update.setId(id);
        update.setStatus(status);
        userMapper.updateById(update);
        // 禁用时吊销该用户全部刷新令牌，让其尽快下线
        if (status == 0) {
            refreshTokenMapper.revokeByUserId(id, REVOKED_REVOKED, "disabled by admin");
        }

        log.info("管理员 {} {} 用户 userId={}", admin.getUsername(), status == 1 ? "启用" : "禁用", id);
        return R.ok(status == 1 ? "已启用" : "已禁用", toSummary(userMapper.selectById(id)));
    }

    // ============================ 4. 角色调整 ============================

    @PutMapping("/users/{id}/role")
    public R<Map<String, Object>> updateRole(@RequestHeader(value = "Authorization", required = false) String authorization,
                                             @PathVariable("id") Long id,
                                             @RequestBody Map<String, String> body) {
        User admin = requireAdmin(authorization);

        String role = body.get("role");
        if (!UserRole.USER.getCode().equals(role) && !UserRole.ADMIN.getCode().equals(role)) {
            throw new BusinessException("role 只能为 user 或 admin");
        }
        User user = requireUser(id);
        if (user.getId().equals(admin.getId())) {
            throw new BusinessException("不能调整自己的角色");
        }

        User update = new User();
        update.setId(id);
        update.setRole(role);
        // permission 与 role 保持同步：admin -> 0（管理员权限），user -> 1（默认权限）
        update.setPermission(UserRole.ADMIN.getCode().equals(role) ? 0 : 1);
        userMapper.updateById(update);

        log.info("管理员 {} 将 userId={} 的角色调整为 {}", admin.getUsername(), id, role);
        return R.ok("角色已更新", toSummary(userMapper.selectById(id)));
    }

    // ============================ 5. 重置密码 ============================

    @PutMapping("/users/{id}/password")
    public R<Map<String, Object>> resetPassword(@RequestHeader(value = "Authorization", required = false) String authorization,
                                                @PathVariable("id") Long id,
                                                @RequestBody Map<String, String> body) {
        User admin = requireAdmin(authorization);

        String password = body.get("password");
        if (password == null || password.length() < 6 || password.length() > 20) {
            throw new BusinessException("新密码需 6-20 位");
        }
        User user = requireUser(id);

        User update = new User();
        update.setId(id);
        update.setPassword(password);
        // 密码版本号 +1：该用户已签发的所有旧 token 立即失效
        update.setPwdVersion((user.getPwdVersion() == null ? 1 : user.getPwdVersion()) + 1);
        userMapper.updateById(update);
        // 吊销全部刷新令牌，强制所有设备重新登录
        refreshTokenMapper.revokeByUserId(id, REVOKED_REVOKED, "password reset by admin");

        log.info("管理员 {} 重置了 userId={} 的密码", admin.getUsername(), id);
        return R.ok("密码已重置", toSummary(userMapper.selectById(id)));
    }

    // ============================ 6. 删除用户 ============================

    @DeleteMapping("/users/{id}")
    public R<Map<String, Object>> deleteUser(@RequestHeader(value = "Authorization", required = false) String authorization,
                                             @PathVariable("id") Long id) {
        User admin = requireAdmin(authorization);

        User user = requireUser(id);
        if (user.getId().equals(admin.getId())) {
            throw new BusinessException("不能删除自己的账号");
        }
        userMapper.deleteById(id);
        refreshTokenMapper.revokeByUserId(id, REVOKED_REVOKED, "user deleted");

        log.info("管理员 {} 删除了用户 userId={}, username={}", admin.getUsername(), id, user.getUsername());
        return R.ok("已删除用户 " + user.getUsername(), null);
    }

    // ============================ 私有工具 ============================

    private User requireUser(Long id) {
        User user = userMapper.selectById(id);
        if (user == null) {
            throw new BusinessException("用户不存在");
        }
        return user;
    }

    /** 转成对外的摘要信息（绝不带密码哈希） */
    private Map<String, Object> toSummary(User u) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getId());
        m.put("username", u.getUsername());
        m.put("phone", u.getPhone());
        m.put("nickname", u.getNickname());
        m.put("status", u.getStatus());
        m.put("role", u.getRole());
        m.put("permission", u.getPermission());
        m.put("lastLoginTime", u.getLastLoginTime());
        m.put("createTime", u.getCreateTime());
        return m;
    }
}
