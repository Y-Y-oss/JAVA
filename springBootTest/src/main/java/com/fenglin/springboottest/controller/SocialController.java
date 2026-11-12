package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.common.BusinessException;
import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.entity.Archive;
import com.fenglin.springboottest.entity.ArchiveComment;
import com.fenglin.springboottest.entity.ArchiveFavorite;
import com.fenglin.springboottest.entity.ArchiveLike;
import com.fenglin.springboottest.mapper.ArchiveCommentMapper;
import com.fenglin.springboottest.mapper.ArchiveFavoriteMapper;
import com.fenglin.springboottest.mapper.ArchiveLikeMapper;
import com.fenglin.springboottest.mapper.ArchiveMapper;
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
 * 社区互动接口（点赞 / 收藏 / 评论，页面见社区档案墙）
 *
 * <pre>
 * 1. 点赞（切换）    ：POST   /api/social/archives/{archiveId}/like       （需登录）
 * 2. 收藏（切换）    ：POST   /api/social/archives/{archiveId}/favorite   （需登录）
 * 3. 互动状态汇总    ：GET    /api/social/archives/{archiveId}/interaction（无需登录；带 token 时返回"我是否点过"）
 * 4. 评论列表        ：GET    /api/social/archives/{archiveId}/comments   （无需登录）
 * 5. 发表评论        ：POST   /api/social/archives/{archiveId}/comments   （需登录）
 * 6. 删除自己的评论  ：DELETE /api/social/comments/{commentId}            （需登录，只能删自己的）
 * </pre>
 */
@Slf4j
@RestController
@RequestMapping("/api/social")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class SocialController {

    @Autowired
    private AuthService authService;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private ArchiveMapper archiveMapper;

    @Autowired
    private ArchiveLikeMapper likeMapper;

    @Autowired
    private ArchiveFavoriteMapper favoriteMapper;

    @Autowired
    private ArchiveCommentMapper commentMapper;

    @Autowired
    private UserMapper userMapper;

    /** 从 Authorization 头取出不含 Bearer 前缀的 token */
    private String resolveToken(String authorization) {
        return authorization == null ? "" : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
    }

    /** 校验已登录，返回当前用户 id */
    private Long requireUserId(String authorization) {
        String token = resolveToken(authorization);
        if (!StringUtils.hasText(token)) {
            throw new BusinessException(401, "登录后才能进行社区互动");
        }
        authService.checkRole(token);
        return jwtUtil.getUserId(token);
    }

    /**
     * 尽力解析当前用户 id：token 缺失/无效时返回 null（浏览互动状态不需要登录）。
     * 注意：绝不能吞掉「账号被禁用」这类明确拒绝——无效 token 才按游客处理。
     */
    private Long optionalUserId(String authorization) {
        String token = resolveToken(authorization);
        if (!StringUtils.hasText(token)) {
            return null;
        }
        try {
            authService.checkRole(token);
            return jwtUtil.getUserId(token);
        } catch (BusinessException e) {
            // 401（未携带/失效）按游客处理；其他业务码（如被禁用）继续抛出
            if (e.getCode() == 401) {
                return null;
            }
            throw e;
        }
    }

    // ============================ 1. 点赞（切换） ============================

    @PostMapping("/archives/{archiveId}/like")
    public R<Map<String, Object>> toggleLike(@RequestHeader(value = "Authorization", required = false) String authorization,
                                             @PathVariable("archiveId") Long archiveId) {
        Long userId = requireUserId(authorization);
        requireArchive(archiveId);

        ArchiveLike existing = likeMapper.selectOne(new LambdaQueryWrapper<ArchiveLike>()
                .eq(ArchiveLike::getArchiveId, archiveId)
                .eq(ArchiveLike::getUserId, userId));
        boolean liked;
        if (existing != null) {
            likeMapper.deleteById(existing.getId());
            liked = false;
            log.info("取消点赞 userId={}, archiveId={}", userId, archiveId);
        } else {
            ArchiveLike like = new ArchiveLike();
            like.setArchiveId(archiveId);
            like.setUserId(userId);
            try {
                likeMapper.insert(like);
            } catch (org.springframework.dao.DuplicateKeyException e) {
                // 并发双击兜底：已存在则视为已点赞
            }
            liked = true;
            log.info("点赞 userId={}, archiveId={}", userId, archiveId);
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("liked", liked);
        data.put("likeCount", countLikes(archiveId));
        return R.ok(liked ? "已点赞" : "已取消点赞", data);
    }

    // ============================ 2. 收藏（切换） ============================

    @PostMapping("/archives/{archiveId}/favorite")
    public R<Map<String, Object>> toggleFavorite(@RequestHeader(value = "Authorization", required = false) String authorization,
                                                 @PathVariable("archiveId") Long archiveId) {
        Long userId = requireUserId(authorization);
        requireArchive(archiveId);

        ArchiveFavorite existing = favoriteMapper.selectOne(new LambdaQueryWrapper<ArchiveFavorite>()
                .eq(ArchiveFavorite::getArchiveId, archiveId)
                .eq(ArchiveFavorite::getUserId, userId));
        boolean favorited;
        if (existing != null) {
            favoriteMapper.deleteById(existing.getId());
            favorited = false;
            log.info("取消收藏 userId={}, archiveId={}", userId, archiveId);
        } else {
            ArchiveFavorite fav = new ArchiveFavorite();
            fav.setArchiveId(archiveId);
            fav.setUserId(userId);
            try {
                favoriteMapper.insert(fav);
            } catch (org.springframework.dao.DuplicateKeyException e) {
                // 并发双击兜底
            }
            favorited = true;
            log.info("收藏 userId={}, archiveId={}", userId, archiveId);
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("favorited", favorited);
        data.put("favoriteCount", countFavorites(archiveId));
        return R.ok(favorited ? "已收藏" : "已取消收藏", data);
    }

    // ============================ 3. 互动状态汇总 ============================

    /**
     * 某档案的互动数据：点赞数 / 收藏数 / 评论数；带 token 时额外返回当前用户是否点过赞、收过藏。
     * 未登录（或 token 失效）时 liked / favorited 固定返回 false，前端据此提示登录。
     */
    @GetMapping("/archives/{archiveId}/interaction")
    public R<Map<String, Object>> interaction(@RequestHeader(value = "Authorization", required = false) String authorization,
                                              @PathVariable("archiveId") Long archiveId) {
        requireArchive(archiveId);
        Long userId = optionalUserId(authorization);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("likeCount", countLikes(archiveId));
        data.put("favoriteCount", countFavorites(archiveId));
        data.put("commentCount", commentMapper.selectCount(
                new LambdaQueryWrapper<ArchiveComment>().eq(ArchiveComment::getArchiveId, archiveId)));
        if (userId != null) {
            data.put("liked", likeMapper.selectCount(new LambdaQueryWrapper<ArchiveLike>()
                    .eq(ArchiveLike::getArchiveId, archiveId)
                    .eq(ArchiveLike::getUserId, userId)) > 0);
            data.put("favorited", favoriteMapper.selectCount(new LambdaQueryWrapper<ArchiveFavorite>()
                    .eq(ArchiveFavorite::getArchiveId, archiveId)
                    .eq(ArchiveFavorite::getUserId, userId)) > 0);
        } else {
            data.put("liked", false);
            data.put("favorited", false);
        }
        return R.ok("查询成功", data);
    }

    // ============================ 4. 评论列表 ============================

    @GetMapping("/archives/{archiveId}/comments")
    public R<List<Map<String, Object>>> comments(@PathVariable("archiveId") Long archiveId) {
        requireArchive(archiveId);
        List<Map<String, Object>> list = commentMapper.selectCommentsWithUser(archiveId).stream()
                .map(this::camelKeys)
                .collect(Collectors.toList());
        return R.ok("查询成功", list);
    }

    // ============================ 5. 发表评论 ============================

    @PostMapping("/archives/{archiveId}/comments")
    public R<Map<String, Object>> addComment(@RequestHeader(value = "Authorization", required = false) String authorization,
                                             @PathVariable("archiveId") Long archiveId,
                                             @RequestBody Map<String, Object> body) {
        Long userId = requireUserId(authorization);
        requireArchive(archiveId);

        Object raw = body == null ? null : body.get("content");
        String content = raw == null ? "" : String.valueOf(raw).trim();
        if (!StringUtils.hasText(content)) {
            throw new BusinessException("评论内容不能为空");
        }
        if (content.length() > 500) {
            throw new BusinessException("评论最多 500 字");
        }

        ArchiveComment comment = new ArchiveComment();
        comment.setArchiveId(archiveId);
        comment.setUserId(userId);
        comment.setContent(content);
        commentMapper.insert(comment);
        log.info("发表评论 userId={}, archiveId={}, commentId={}", userId, archiveId, comment.getId());

        // 返回带用户名的完整评论（前端直接追加到列表，不用再拉一次）
        List<Map<String, Object>> rows = commentMapper.selectCommentsWithUser(archiveId);
        Map<String, Object> saved = rows.stream()
                .filter(r -> ((Number) r.get("id")).longValue() == comment.getId())
                .findFirst().orElse(null);
        if (saved == null) {
            // 兜底：JOIN 查询没捞到刚插入的行（理论上不会发生），手动拼一份返回
            com.fenglin.springboottest.entity.User user = userMapper.selectById(userId);
            saved = new LinkedHashMap<>();
            saved.put("id", comment.getId());
            saved.put("archiveId", archiveId);
            saved.put("userId", userId);
            saved.put("username", user == null ? "" : user.getUsername());
            saved.put("content", content);
            saved.put("createTime", comment.getCreateTime());
        }
        return R.ok("评论已发表", camelKeys(saved));
    }

    // ============================ 6. 删除自己的评论 ============================

    @DeleteMapping("/comments/{commentId}")
    public R<Map<String, Object>> deleteComment(@RequestHeader(value = "Authorization", required = false) String authorization,
                                                @PathVariable("commentId") Long commentId) {
        Long userId = requireUserId(authorization);
        ArchiveComment comment = commentMapper.selectById(commentId);
        if (comment == null) {
            throw new BusinessException("评论不存在或已被删除");
        }
        if (!comment.getUserId().equals(userId)) {
            throw new BusinessException(403, "只能删除自己的评论");
        }
        commentMapper.deleteById(commentId);
        log.info("删除评论 userId={}, commentId={}", userId, commentId);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", commentId);
        return R.ok("评论已删除", data);
    }

    // ============================ 私有工具 ============================

    private Archive requireArchive(Long archiveId) {
        Archive archive = archiveMapper.selectById(archiveId);
        if (archive == null) {
            throw new BusinessException("档案不存在或已被删除");
        }
        return archive;
    }

    private long countLikes(Long archiveId) {
        return likeMapper.selectCount(new LambdaQueryWrapper<ArchiveLike>()
                .eq(ArchiveLike::getArchiveId, archiveId));
    }

    private long countFavorites(Long archiveId) {
        return favoriteMapper.selectCount(new LambdaQueryWrapper<ArchiveFavorite>()
                .eq(ArchiveFavorite::getArchiveId, archiveId));
    }

    /** 数据库下划线列名 -> 驼峰键名（JOIN 查询结果用，与 ArchiveController 保持一致） */
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
