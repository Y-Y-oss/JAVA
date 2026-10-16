package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fenglin.springboottest.common.BusinessException;
import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.dto.ArchiveDTO;
import com.fenglin.springboottest.entity.Archive;
import com.fenglin.springboottest.mapper.ArchiveMapper;
import com.fenglin.springboottest.service.AuthService;
import com.fenglin.springboottest.util.JwtUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.util.StringUtils;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 时光档案接口（「时光代理人」核心业务，页面见 static/archives/index.html）
 *
 * <pre>
 * 1. 我的档案列表：GET    /api/archives?page=1&amp;size=10   （需登录，只看自己的）
 * 2. 档案详情    ：GET    /api/archives/{id}              （需登录，只能看自己的或公开的）
 * 3. 新建档案    ：POST   /api/archives                   （需登录）
 * 4. 编辑档案    ：PUT    /api/archives/{id}              （需登录，只能改自己的）
 * 5. 删除档案    ：DELETE /api/archives/{id}              （需登录，只能删自己的）
 * 6. 公开档案墙  ：GET    /api/archives/public?page=1     （无需登录，展示 visibility=1 的档案）
 * 7. 搜索我的档案：GET    /api/archives/search?q=关键字    （需登录，仅搜自己的，标题/内容/标签/日期）
 * 8. 搜索档案墙  ：GET    /api/archives/public/search?q=  （无需登录，跨所有用户公开档案，带作者名）
 * </pre>
 */
@Slf4j
@RestController
@RequestMapping("/api/archives")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class ArchiveController {

    @Autowired
    private AuthService authService;

    @Autowired
    private ArchiveMapper archiveMapper;

    @Autowired
    private JwtUtil jwtUtil;

    /** 从 Authorization 头取出不含 Bearer 前缀的 token */
    private String resolveToken(String authorization) {
        return authorization == null ? "" : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
    }

    /** 校验已登录，返回当前用户 id */
    private Long requireUserId(String authorization) {
        String token = resolveToken(authorization);
        if (!StringUtils.hasText(token)) {
            throw new BusinessException(401, "未携带登录凭证，请重新登录");
        }
        authService.checkRole(token);
        return jwtUtil.getUserId(token);
    }

    // ============================ 1. 我的档案列表 ============================

    @GetMapping
    public R<Map<String, Object>> list(@RequestHeader(value = "Authorization", required = false) String authorization,
                                       @RequestParam(value = "page", defaultValue = "1") long page,
                                       @RequestParam(value = "size", defaultValue = "10") long size) {
        Long userId = requireUserId(authorization);
        if (page < 1) page = 1;
        if (size < 1 || size > 50) size = 10;

        // MyBatis-Plus 分页插件（MybatisPlusConfig 已注册）自动补 LIMIT 和 COUNT
        Page<Archive> result = archiveMapper.selectPage(
                new Page<>(page, size),
                new LambdaQueryWrapper<Archive>()
                        .eq(Archive::getUserId, userId)
                        .orderByDesc(Archive::getUpdateTime));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total", result.getTotal());
        data.put("page", page);
        data.put("size", size);
        data.put("records", result.getRecords());
        return R.ok("查询成功", data);
    }

    // ============================ 2. 档案详情 ============================

    @GetMapping("/{id}")
    public R<Archive> detail(@RequestHeader(value = "Authorization", required = false) String authorization,
                             @PathVariable("id") Long id) {
        Long userId = requireUserId(authorization);
        Archive archive = requireArchive(id);

        // 只能看自己的，或别人公开到档案墙的
        boolean own = archive.getUserId().equals(userId);
        boolean open = archive.getVisibility() != null && archive.getVisibility() == 1;
        if (!own && !open) {
            throw new BusinessException(403, "这份档案是私密的，你没有权限查看");
        }
        return R.ok("查询成功", archive);
    }

    // ============================ 3. 新建档案 ============================

    @PostMapping
    public R<Archive> create(@RequestHeader(value = "Authorization", required = false) String authorization,
                             @RequestBody @Validated ArchiveDTO dto) {
        Long userId = requireUserId(authorization);

        Archive archive = new Archive();
        archive.setUserId(userId);
        applyDto(archive, dto);
        archiveMapper.insert(archive);

        log.info("新建档案 userId={}, archiveId={}, title={}", userId, archive.getId(), archive.getTitle());
        return R.ok("档案已封存进时光长廊", archive);
    }

    // ============================ 4. 编辑档案 ============================

    @PutMapping("/{id}")
    public R<Archive> update(@RequestHeader(value = "Authorization", required = false) String authorization,
                             @PathVariable("id") Long id,
                             @RequestBody @Validated ArchiveDTO dto) {
        Long userId = requireUserId(authorization);
        Archive archive = requireArchive(id);
        if (!archive.getUserId().equals(userId)) {
            throw new BusinessException(403, "只能编辑自己的档案");
        }

        applyDto(archive, dto);
        archiveMapper.updateById(archive);

        log.info("编辑档案 userId={}, archiveId={}", userId, id);
        return R.ok("档案已更新", archive);
    }

    // ============================ 5. 删除档案 ============================

    @DeleteMapping("/{id}")
    public R<Map<String, Object>> delete(@RequestHeader(value = "Authorization", required = false) String authorization,
                                         @PathVariable("id") Long id) {
        Long userId = requireUserId(authorization);
        Archive archive = requireArchive(id);
        if (!archive.getUserId().equals(userId)) {
            throw new BusinessException(403, "只能删除自己的档案");
        }
        archiveMapper.deleteById(id);

        log.info("删除档案 userId={}, archiveId={}", userId, id);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", id);
        return R.ok("档案已从时光长廊抹去", data);
    }

    // ============================ 6. 公开档案墙 ============================

    /**
     * 档案墙：展示所有用户公开（visibility=1）的档案，无需登录。
     * 与 DemoController 里写死的假数据不同，这里是真实业务数据。
     */
    @GetMapping("/public")
    public R<Map<String, Object>> publicWall(@RequestParam(value = "page", defaultValue = "1") long page,
                                             @RequestParam(value = "size", defaultValue = "10") long size) {
        if (page < 1) page = 1;
        if (size < 1 || size > 50) size = 10;

        List<Map<String, Object>> records = archiveMapper.selectPublicWall((page - 1) * size, size);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total", archiveMapper.countPublic());
        data.put("page", page);
        data.put("size", size);
        data.put("records", records.stream().map(this::camelKeys).collect(Collectors.toList()));
        return R.ok("查询成功", data);
    }

    // ============================ 7. 搜索我的档案 ============================

    /**
     * 搜索「我的档案」：按 标题/内容/标签/时光节点 模糊匹配，仅看自己的。
     * 首页搜索框对接此接口（需登录）。q 为空时退化为「列出我的全部档案」。
     */
    @GetMapping("/search")
    public R<Map<String, Object>> search(@RequestHeader(value = "Authorization", required = false) String authorization,
                                        @RequestParam(value = "q", required = false) String q,
                                        @RequestParam(value = "page", defaultValue = "1") long page,
                                        @RequestParam(value = "size", defaultValue = "10") long size) {
        Long userId = requireUserId(authorization);
        if (page < 1) page = 1;
        if (size < 1 || size > 50) size = 10;
        String kw = StringUtils.hasText(q) ? q.trim() : "";

        LambdaQueryWrapper<Archive> qw = new LambdaQueryWrapper<Archive>()
                .eq(Archive::getUserId, userId)
                .orderByDesc(Archive::getUpdateTime);
        if (StringUtils.hasText(kw)) {
            qw.and(w -> w.like(Archive::getTitle, kw)
                    .or().like(Archive::getContent, kw)
                    .or().like(Archive::getTag, kw)
                    .or().like(Archive::getArchiveDate, kw));
        }

        Page<Archive> result = archiveMapper.selectPage(new Page<>(page, size), qw);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total", result.getTotal());
        data.put("page", page);
        data.put("size", size);
        data.put("keyword", kw);
        data.put("records", result.getRecords());
        return R.ok(StringUtils.hasText(kw) ? "搜索完成" : "查询成功", data);
    }

    // ============================ 8. 搜索公开档案墙 ============================

    /**
     * 搜索公开档案墙（visibility=1），无需登录，带作者用户名。
     * 与 {@code /search} 的区别：跨所有用户的公开档案，且返回带 username。
     * q 为空时退化为「列出全部公开档案」。
     */
    @GetMapping("/public/search")
    public R<Map<String, Object>> searchPublic(@RequestParam(value = "q", required = false) String q,
                                               @RequestParam(value = "page", defaultValue = "1") long page,
                                               @RequestParam(value = "size", defaultValue = "10") long size) {
        if (page < 1) page = 1;
        if (size < 1 || size > 50) size = 10;
        String kw = StringUtils.hasText(q) ? q.trim() : "";

        List<Map<String, Object>> records = archiveMapper.searchPublicWall(kw, (page - 1) * size, size);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total", archiveMapper.countSearchPublic(kw));
        data.put("page", page);
        data.put("size", size);
        data.put("keyword", kw);
        data.put("records", records.stream().map(this::camelKeys).collect(Collectors.toList()));
        return R.ok("搜索完成", data);
    }

    // ============================ 私有工具 ============================

    private Archive requireArchive(Long id) {
        Archive archive = archiveMapper.selectById(id);
        if (archive == null) {
            throw new BusinessException("档案不存在或已被删除");
        }
        return archive;
    }

    /** 把 DTO 内容套到实体上（标题/内容/日期/标签/可见性） */
    private void applyDto(Archive archive, ArchiveDTO dto) {
        archive.setTitle(dto.getTitle().trim());
        archive.setContent(StringUtils.hasText(dto.getContent()) ? dto.getContent().trim() : null);
        archive.setArchiveDate(parseDate(dto.getArchiveDate()));
        archive.setTag(StringUtils.hasText(dto.getTag()) ? dto.getTag().trim() : null);
        archive.setVisibility(dto.getVisibility() != null && dto.getVisibility() == 1 ? 1 : 0);
    }

    /** 日期字符串 -> LocalDate，格式错误直接抛业务异常 */
    private LocalDate parseDate(String date) {
        if (!StringUtils.hasText(date)) {
            return null;
        }
        try {
            return LocalDate.parse(date.trim());
        } catch (DateTimeParseException e) {
            throw new BusinessException("时光节点日期格式不正确，应为 yyyy-MM-dd");
        }
    }

    /** 数据库下划线列名 -> 驼峰键名（档案墙 JOIN 查询结果用） */
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
