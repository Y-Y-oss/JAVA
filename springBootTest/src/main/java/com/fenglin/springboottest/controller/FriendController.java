package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.common.BusinessException;
import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.entity.Friend;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.FriendMapper;
import com.fenglin.springboottest.mapper.UserMapper;
import com.fenglin.springboottest.service.AuthService;
import com.fenglin.springboottest.util.JwtUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 好友接口（社区页「好友」面板）
 *
 * <pre>
 * 1. 申请添加好友  ：POST   /api/friends/apply {username}   （需登录，对方验证后才成为好友）
 * 2. 同意申请      ：POST   /api/friends/apply/{id}/accept  （需登录，只能同意发给自己的）
 * 3. 拒绝申请      ：POST   /api/friends/apply/{id}/reject  （需登录）
 * 4. 我的好友列表  ：GET    /api/friends                    （需登录）
 * 5. 收到的待验证  ：GET    /api/friends/pending            （需登录）
 * 6. 我发出的申请  ：GET    /api/friends/sent               （需登录）
 * 7. 删除好友      ：DELETE /api/friends/{friendUserId}     （需登录，双向一起删）
 * </pre>
 */
@Slf4j
@RestController
@RequestMapping("/api/friends")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class FriendController {

    @Autowired
    private AuthService authService;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private FriendMapper friendMapper;

    @Autowired
    private UserMapper userMapper;

    private String resolveToken(String authorization) {
        return authorization == null ? "" : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
    }

    private Long requireUserId(String authorization) {
        String token = resolveToken(authorization);
        if (!StringUtils.hasText(token)) {
            throw new BusinessException(401, "未携带登录凭证，请重新登录");
        }
        authService.checkRole(token);
        return jwtUtil.getUserId(token);
    }

    // ============================ 1. 申请添加好友 ============================

    @PostMapping("/apply")
    public R<Map<String, Object>> apply(@RequestHeader(value = "Authorization", required = false) String authorization,
                                        @RequestBody Map<String, Object> body) {
        Long me = requireUserId(authorization);
        String username = body == null || body.get("username") == null ? "" : String.valueOf(body.get("username")).trim();
        if (!StringUtils.hasText(username)) {
            throw new BusinessException("请填写要添加的用户名");
        }
        User target = userMapper.selectOne(new LambdaQueryWrapper<User>().eq(User::getUsername, username));
        if (target == null) {
            throw new BusinessException("用户「" + username + "」不存在");
        }
        if (target.getId().equals(me)) {
            throw new BusinessException("不能添加自己为好友");
        }

        // 已是好友（任一方向）→ 拒绝重复添加
        Long mine = friendMapper.selectCount(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getUserId, me).eq(Friend::getFriendId, target.getId()).eq(Friend::getStatus, 1));
        Long theirs = friendMapper.selectCount(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getUserId, target.getId()).eq(Friend::getFriendId, me).eq(Friend::getStatus, 1));
        if (mine > 0 || theirs > 0) {
            throw new BusinessException("你们已经是好友了");
        }

        // 对方已向我发起待验证申请 → 直接提示去「收到的申请」里同意，避免两边各挂一条
        Long incoming = friendMapper.selectCount(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getUserId, target.getId()).eq(Friend::getFriendId, me).eq(Friend::getStatus, 0));
        if (incoming > 0) {
            throw new BusinessException("对方已向你发来好友申请，请在「收到的申请」里验证");
        }

        // 我先前发过且还没被处理 → 不重复发
        Long outgoing = friendMapper.selectCount(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getUserId, me).eq(Friend::getFriendId, target.getId()).eq(Friend::getStatus, 0));
        if (outgoing > 0) {
            throw new BusinessException("申请已发送，等待对方验证");
        }

        Friend apply = new Friend();
        apply.setUserId(me);
        apply.setFriendId(target.getId());
        apply.setStatus(0);
        friendMapper.insert(apply);
        log.info("好友申请 me={}, target={}", me, target.getId());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", apply.getId());
        data.put("targetUserId", target.getId());
        data.put("targetUsername", target.getUsername());
        return R.ok("好友申请已发送，等待对方验证", data);
    }

    // ============================ 2. 同意申请 ============================

    @PostMapping("/apply/{id}/accept")
    public R<Map<String, Object>> accept(@RequestHeader(value = "Authorization", required = false) String authorization,
                                         @PathVariable("id") Long id) {
        Long me = requireUserId(authorization);
        Friend apply = requirePending(id, me);

        apply.setStatus(1);
        friendMapper.updateById(apply);

        // 建立反向关系（互为好友 = 双向各一行）；唯一键兜底并发
        Friend reverse = new Friend();
        reverse.setUserId(me);
        reverse.setFriendId(apply.getUserId());
        reverse.setStatus(1);
        try {
            friendMapper.insert(reverse);
        } catch (org.springframework.dao.DuplicateKeyException e) {
            // 已存在则视为已同意
        }
        log.info("好友申请通过 me={}, from={}", me, apply.getUserId());

        User from = userMapper.selectById(apply.getUserId());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("friendUserId", apply.getUserId());
        data.put("username", from == null ? "" : from.getUsername());
        return R.ok("已通过好友验证，你们现在是好友了", data);
    }

    // ============================ 3. 拒绝申请 ============================

    @PostMapping("/apply/{id}/reject")
    public R<Map<String, Object>> reject(@RequestHeader(value = "Authorization", required = false) String authorization,
                                         @PathVariable("id") Long id) {
        Long me = requireUserId(authorization);
        requirePending(id, me);
        friendMapper.deleteById(id);
        return R.ok("已拒绝该好友申请", new LinkedHashMap<>());
    }

    // ============================ 4/5/6. 列表 ============================

    @GetMapping
    public R<List<Map<String, Object>>> list(@RequestHeader(value = "Authorization", required = false) String authorization) {
        Long me = requireUserId(authorization);
        return R.ok("查询成功", friendMapper.selectFriends(me).stream().map(this::camelKeys).collect(Collectors.toList()));
    }

    @GetMapping("/pending")
    public R<List<Map<String, Object>>> pending(@RequestHeader(value = "Authorization", required = false) String authorization) {
        Long me = requireUserId(authorization);
        return R.ok("查询成功", friendMapper.selectPendingIncoming(me).stream().map(this::camelKeys).collect(Collectors.toList()));
    }

    @GetMapping("/sent")
    public R<List<Map<String, Object>>> sent(@RequestHeader(value = "Authorization", required = false) String authorization) {
        Long me = requireUserId(authorization);
        return R.ok("查询成功", friendMapper.selectPendingOutgoing(me).stream().map(this::camelKeys).collect(Collectors.toList()));
    }

    // ============================ 7. 删除好友 ============================

    @DeleteMapping("/{friendUserId}")
    public R<Map<String, Object>> remove(@RequestHeader(value = "Authorization", required = false) String authorization,
                                         @PathVariable("friendUserId") Long friendUserId) {
        Long me = requireUserId(authorization);
        Long a = friendMapper.selectCount(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getUserId, me).eq(Friend::getFriendId, friendUserId).eq(Friend::getStatus, 1));
        Long b = friendMapper.selectCount(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getUserId, friendUserId).eq(Friend::getFriendId, me).eq(Friend::getStatus, 1));
        if (a == 0 && b == 0) {
            throw new BusinessException("你们本来就不是好友");
        }
        friendMapper.delete(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getUserId, me).eq(Friend::getFriendId, friendUserId));
        friendMapper.delete(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getUserId, friendUserId).eq(Friend::getFriendId, me));
        log.info("删除好友 me={}, friend={}", me, friendUserId);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("removed", friendUserId);
        return R.ok("好友已删除", data);
    }

    // ============================ 私有工具 ============================

    /** 校验申请存在、发给我、且还在待验证状态 */
    private Friend requirePending(Long id, Long me) {
        Friend apply = friendMapper.selectById(id);
        if (apply == null) {
            throw new BusinessException("申请不存在或已被处理");
        }
        if (!apply.getFriendId().equals(me)) {
            throw new BusinessException(403, "只能处理发给自己的好友申请");
        }
        if (apply.getStatus() == null || apply.getStatus() != 0) {
            throw new BusinessException("该申请已被处理过");
        }
        return apply;
    }

    /** 数据库下划线列名 -> 驼峰键名 */
    private Map<String, Object> camelKeys(Map<String, Object> row) {
        Map<String, Object> m = new LinkedHashMap<>();
        row.forEach((k, v) -> {
            String[] parts = k.split("_");
            StringBuilder sb = new StringBuilder(parts[0]);
            for (int i = 1; i < parts.length; i++) {
                sb.append(Character.toUpperCase(parts[i].charAt(0))).append(parts[i].substring(1));
            }
            m.put(sb.toString(), v);
        });
        return m;
    }
}
