package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.LambdaUpdateWrapper;
import com.fenglin.springboottest.common.BusinessException;
import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.entity.ChatMessage;
import com.fenglin.springboottest.entity.Friend;
import com.fenglin.springboottest.mapper.ChatMessageMapper;
import com.fenglin.springboottest.mapper.FriendMapper;
import com.fenglin.springboottest.service.AuthService;
import com.fenglin.springboottest.util.JwtUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 好友聊天接口（导航栏「好友聊天」面板）
 *
 * <pre>
 * 1. 会话总览        ：GET  /api/chat/conversations            （需登录）
 * 2. 未读消息总数    ：GET  /api/chat/unread                   （需登录，轮询红点用）
 * 3. 聊天历史        ：GET  /api/chat/{friendId}/messages      （需登录；自动把对方发来的消息标记为已读）
 * 4. 发送消息        ：POST /api/chat/{friendId}/messages      （需登录，双方必须是好友）
 * 5. 标记已读        ：POST /api/chat/{friendId}/read          （需登录）
 * </pre>
 */
@Slf4j
@RestController
@RequestMapping("/api/chat")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class ChatController {

    /** 每页聊天记录条数 */
    private static final int PAGE_SIZE = 50;
    /** 单条消息最大长度 */
    private static final int MAX_LEN = 1000;

    @Autowired
    private AuthService authService;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private ChatMessageMapper chatMapper;

    @Autowired
    private FriendMapper friendMapper;

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

    // ============================ 1. 会话总览 ============================

    /** 每个好友的最近一条消息、未读数、头像昵称；前端打开聊天面板时调用 */
    @GetMapping("/conversations")
    public R<List<Map<String, Object>>> conversations(@RequestHeader(value = "Authorization", required = false) String authorization) {
        Long me = requireUserId(authorization);
        return R.ok("查询成功", chatMapper.selectConversations(me).stream().map(this::camelKeys).collect(Collectors.toList()));
    }

    // ============================ 2. 未读总数（红点轮询） ============================

    @GetMapping("/unread")
    public R<Map<String, Object>> unread(@RequestHeader(value = "Authorization", required = false) String authorization) {
        Long me = requireUserId(authorization);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total", chatMapper.countUnread(me));
        return R.ok("查询成功", data);
    }

    // ============================ 3. 聊天历史 ============================

    /**
     * 与某好友的聊天记录，倒序取最新一页；beforeId 不为 0 时往上翻更早的。
     * 每次拉取都会把「对方发给我」的未读消息标记为已读。
     */
    @GetMapping("/{friendId}/messages")
    public R<List<Map<String, Object>>> history(@RequestHeader(value = "Authorization", required = false) String authorization,
                                                @PathVariable("friendId") Long friendId,
                                                @RequestParam(value = "beforeId", defaultValue = "0") Long beforeId) {
        Long me = requireUserId(authorization);
        requireFriend(me, friendId);
        markRead(me, friendId);

        List<Map<String, Object>> list = chatMapper.selectHistory(me, friendId, beforeId, PAGE_SIZE);
        // 查询按 id 倒序取最新一页，前端按时间正序渲染，这里翻个顺序
        java.util.Collections.reverse(list);
        return R.ok("查询成功", list.stream().map(this::camelKeys).collect(Collectors.toList()));
    }

    // ============================ 4. 发送消息 ============================

    @PostMapping("/{friendId}/messages")
    public R<Map<String, Object>> send(@RequestHeader(value = "Authorization", required = false) String authorization,
                                       @PathVariable("friendId") Long friendId,
                                       @RequestBody Map<String, Object> body) {
        Long me = requireUserId(authorization);
        requireFriend(me, friendId);

        Object raw = body == null ? null : body.get("content");
        String content = raw == null ? "" : String.valueOf(raw).trim();
        if (!StringUtils.hasText(content)) {
            throw new BusinessException("消息内容不能为空");
        }
        if (content.length() > MAX_LEN) {
            throw new BusinessException("单条消息最多 " + MAX_LEN + " 字");
        }

        ChatMessage msg = new ChatMessage();
        msg.setSenderId(me);
        msg.setReceiverId(friendId);
        msg.setContent(content);
        msg.setReadFlag(0);
        chatMapper.insert(msg);
        log.info("发送私信 me={}, to={}, msgId={}", me, friendId, msg.getId());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", msg.getId());
        data.put("senderId", me);
        data.put("receiverId", friendId);
        data.put("content", content);
        data.put("readFlag", 0);
        data.put("createTime", msg.getCreateTime());
        return R.ok("消息已发送", data);
    }

    // ============================ 5. 标记已读 ============================

    @PostMapping("/{friendId}/read")
    public R<Map<String, Object>> markReadApi(@RequestHeader(value = "Authorization", required = false) String authorization,
                                              @PathVariable("friendId") Long friendId) {
        Long me = requireUserId(authorization);
        markRead(me, friendId);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("unread", chatMapper.countUnread(me));
        return R.ok("已标记为已读", data);
    }

    // ============================ 私有工具 ============================

    /** 校验双方已是好友（status=1），否则拒绝聊天 */
    private void requireFriend(Long me, Long friendId) {
        if (me.equals(friendId)) {
            throw new BusinessException("不能和自己聊天");
        }
        Long count = friendMapper.selectCount(new LambdaQueryWrapper<Friend>()
                .eq(Friend::getUserId, me)
                .eq(Friend::getFriendId, friendId)
                .eq(Friend::getStatus, 1));
        if (count == 0) {
            throw new BusinessException(403, "只有好友之间才能发消息");
        }
    }

    /** 把「对方发给我」的未读消息标记为已读 */
    private void markRead(Long me, Long friendId) {
        chatMapper.update(null, new LambdaUpdateWrapper<ChatMessage>()
                .eq(ChatMessage::getSenderId, friendId)
                .eq(ChatMessage::getReceiverId, me)
                .eq(ChatMessage::getReadFlag, 0)
                .set(ChatMessage::getReadFlag, 1));
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
