package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.BusinessException;
import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.entity.ForumPost;
import com.fenglin.springboottest.entity.ForumReply;
import com.fenglin.springboottest.entity.User;
import com.fenglin.springboottest.mapper.ForumPostMapper;
import com.fenglin.springboottest.mapper.ForumReplyMapper;
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
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 论坛接口（导航栏「论坛」面板，所有人可看，登录后可发帖/回复）
 *
 * <pre>
 * 1. 帖子列表        ：GET    /api/forum/posts?page=1&size=20   （无需登录）
 * 2. 发布帖子        ：POST   /api/forum/posts                  （需登录）
 * 3. 帖子详情+回复   ：GET    /api/forum/posts/{postId}         （无需登录）
 * 4. 发表回复        ：POST   /api/forum/posts/{postId}/replies （需登录）
 * 5. 删除自己的帖子  ：DELETE /api/forum/posts/{postId}         （需登录，管理员也可删）
 * 6. 删除自己的回复  ：DELETE /api/forum/replies/{replyId}      （需登录，管理员也可删）
 * </pre>
 */
@Slf4j
@RestController
@RequestMapping("/api/forum")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class ForumController {

    private static final int TITLE_MAX = 100;
    private static final int POST_MAX = 3000;
    private static final int REPLY_MAX = 500;

    @Autowired
    private AuthService authService;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private ForumPostMapper postMapper;

    @Autowired
    private ForumReplyMapper replyMapper;

    @Autowired
    private UserMapper userMapper;

    private String resolveToken(String authorization) {
        return authorization == null ? "" : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
    }

    private Long requireUserId(String authorization) {
        String token = resolveToken(authorization);
        if (!StringUtils.hasText(token)) {
            throw new BusinessException(401, "登录后才能发帖和回复");
        }
        authService.checkRole(token);
        return jwtUtil.getUserId(token);
    }

    /** 与 SocialController 一致：无效 token 按游客处理（浏览不需要登录） */
    private Long optionalUserId(String authorization) {
        String token = resolveToken(authorization);
        if (!StringUtils.hasText(token)) {
            return null;
        }
        try {
            authService.checkRole(token);
            return jwtUtil.getUserId(token);
        } catch (BusinessException e) {
            if (e.getCode() == 401) {
                return null;
            }
            throw e;
        }
    }

    // ============================ 1. 帖子列表 ============================

    @GetMapping("/posts")
    public R<Map<String, Object>> posts(@RequestParam(value = "page", defaultValue = "1") long page,
                                        @RequestParam(value = "size", defaultValue = "20") int size) {
        long p = Math.max(1, page);
        int s = Math.min(Math.max(1, size), 50);
        long total = postMapper.selectCount(null);
        List<Map<String, Object>> list = postMapper.selectPostList((p - 1) * s, s).stream()
                .map(this::camelKeys)
                .collect(Collectors.toList());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total", total);
        data.put("page", p);
        data.put("size", s);
        data.put("records", list);
        return R.ok("查询成功", data);
    }

    // ============================ 2. 发布帖子 ============================

    @PostMapping("/posts")
    public R<Map<String, Object>> createPost(@RequestHeader(value = "Authorization", required = false) String authorization,
                                             @RequestBody Map<String, Object> body) {
        Long me = requireUserId(authorization);
        String title = str(body, "title");
        String content = str(body, "content");
        if (!StringUtils.hasText(title)) {
            throw new BusinessException("帖子标题不能为空");
        }
        if (title.length() > TITLE_MAX) {
            throw new BusinessException("标题最多 " + TITLE_MAX + " 字");
        }
        if (!StringUtils.hasText(content)) {
            throw new BusinessException("帖子内容不能为空");
        }
        if (content.length() > POST_MAX) {
            throw new BusinessException("内容最多 " + POST_MAX + " 字");
        }

        ForumPost post = new ForumPost();
        post.setUserId(me);
        post.setTitle(title);
        post.setContent(content);
        post.setReplyCount(0);
        postMapper.insert(post);
        log.info("发布帖子 userId={}, postId={}", me, post.getId());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", post.getId());
        return R.ok("帖子已发布", data);
    }

    // ============================ 3. 帖子详情 + 回复 ============================

    @GetMapping("/posts/{postId}")
    public R<Map<String, Object>> detail(@RequestHeader(value = "Authorization", required = false) String authorization,
                                         @PathVariable("postId") Long postId) {
        Map<String, Object> post = postMapper.selectPostDetail(postId);
        if (post == null) {
            throw new BusinessException("帖子不存在或已被删除");
        }
        Map<String, Object> data = camelKeys(post);
        data.put("replies", replyMapper.selectReplies(postId).stream().map(this::camelKeys).collect(Collectors.toList()));
        return R.ok("查询成功", data);
    }

    // ============================ 4. 发表回复 ============================

    @PostMapping("/posts/{postId}/replies")
    public R<Map<String, Object>> addReply(@RequestHeader(value = "Authorization", required = false) String authorization,
                                           @PathVariable("postId") Long postId,
                                           @RequestBody Map<String, Object> body) {
        Long me = requireUserId(authorization);
        ForumPost post = postMapper.selectById(postId);
        if (post == null) {
            throw new BusinessException("帖子不存在或已被删除");
        }
        String content = str(body, "content");
        if (!StringUtils.hasText(content)) {
            throw new BusinessException("回复内容不能为空");
        }
        if (content.length() > REPLY_MAX) {
            throw new BusinessException("回复最多 " + REPLY_MAX + " 字");
        }

        ForumReply reply = new ForumReply();
        reply.setPostId(postId);
        reply.setUserId(me);
        reply.setContent(content);
        replyMapper.insert(reply);

        // 同步维护帖子的回复数
        post.setReplyCount((post.getReplyCount() == null ? 0 : post.getReplyCount()) + 1);
        postMapper.updateById(post);
        log.info("发表回复 userId={}, postId={}, replyId={}", me, postId, reply.getId());

        // 返回带用户信息的完整回复，前端直接追加渲染
        User user = userMapper.selectById(me);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", reply.getId());
        data.put("postId", postId);
        data.put("userId", me);
        data.put("content", content);
        data.put("createTime", reply.getCreateTime());
        data.put("username", user == null ? "" : user.getUsername());
        data.put("nickname", user == null ? "" : user.getNickname());
        data.put("avatar", user == null ? "" : user.getAvatar());
        data.put("replyCount", post.getReplyCount());
        return R.ok("回复已发表", data);
    }

    // ============================ 5. 删除帖子 ============================

    @DeleteMapping("/posts/{postId}")
    public R<Map<String, Object>> deletePost(@RequestHeader(value = "Authorization", required = false) String authorization,
                                             @PathVariable("postId") Long postId) {
        Long me = requireUserId(authorization);
        ForumPost post = postMapper.selectById(postId);
        if (post == null) {
            throw new BusinessException("帖子不存在或已被删除");
        }
        requireOwnerOrAdmin(authorization, post.getUserId(), "只能删除自己的帖子");
        // 连带清掉回复
        replyMapper.delete(new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<ForumReply>()
                .eq(ForumReply::getPostId, postId));
        postMapper.deleteById(postId);
        log.info("删除帖子 userId={}, postId={}", me, postId);
        return R.ok("帖子已删除", new LinkedHashMap<>());
    }

    // ============================ 6. 删除回复 ============================

    @DeleteMapping("/replies/{replyId}")
    public R<Map<String, Object>> deleteReply(@RequestHeader(value = "Authorization", required = false) String authorization,
                                              @PathVariable("replyId") Long replyId) {
        Long me = requireUserId(authorization);
        ForumReply reply = replyMapper.selectById(replyId);
        if (reply == null) {
            throw new BusinessException("回复不存在或已被删除");
        }
        requireOwnerOrAdmin(authorization, reply.getUserId(), "只能删除自己的回复");

        replyMapper.deleteById(replyId);
        ForumPost post = postMapper.selectById(reply.getPostId());
        if (post != null) {
            post.setReplyCount(Math.max(0, (post.getReplyCount() == null ? 0 : post.getReplyCount()) - 1));
            postMapper.updateById(post);
        }
        log.info("删除回复 userId={}, replyId={}", me, replyId);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("replyCount", post == null ? 0 : post.getReplyCount());
        return R.ok("回复已删除", data);
    }

    // ============================ 私有工具 ============================

    private String str(Map<String, Object> body, String key) {
        Object raw = body == null ? null : body.get(key);
        return raw == null ? "" : String.valueOf(raw).trim();
    }

    /** 作者本人可删；管理员（permission=0）也可删任意内容 */
    private void requireOwnerOrAdmin(String authorization, Long ownerId, String msg) {
        Long me = requireUserId(authorization);
        if (me.equals(ownerId)) {
            return;
        }
        String token = resolveToken(authorization);
        User user = userMapper.selectById(me);
        boolean admin = user != null && Integer.valueOf(0).equals(user.getPermission());
        if (!admin) {
            throw new BusinessException(403, msg);
        }
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
