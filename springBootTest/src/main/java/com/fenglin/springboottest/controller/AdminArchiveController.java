package com.fenglin.springboottest.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.common.BusinessException;
import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.dto.ArchiveDTO;
import com.fenglin.springboottest.entity.Archive;
import com.fenglin.springboottest.mapper.ArchiveMapper;
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
import java.time.format.DateTimeParseException;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 管理后台 · 时光档案数据管理（仅 ADMIN 角色可访问，页面见 static/admin/index.html 的「时光档案」标签页）
 *
 * <pre>
 * 1. 档案统计：GET    /api/admin/archives/stats
 * 2. 档案列表：GET    /api/admin/archives?keyword=&amp;visibility=&amp;page=1&amp;size=10
 * 3. 档案详情：GET    /api/admin/archives/{id}
 * 4. 编辑档案：PUT    /api/admin/archives/{id}     （body: ArchiveDTO）
 * 5. 删除档案：DELETE /api/admin/archives/{id}
 * </pre>
 *
 * <p>沿用项目「Controller 手动解析 Authorization 头 + authService.checkRole」的鉴权风格，
 * 与 AdminUserController 保持一致。档案属于全体用户，管理员可越权查看 / 编辑 / 删除任意档案。</p>
 */
@Slf4j
@RestController
@RequestMapping("/api/admin/archives")
@CrossOrigin(origins = "*", allowedHeaders = "*")
public class AdminArchiveController {

    @Autowired
    private AuthService authService;

    @Autowired
    private ArchiveMapper archiveMapper;

    /** 从 Authorization 头取出不含 Bearer 前缀的 token */
    private String resolveToken(String authorization) {
        return authorization == null ? "" : authorization.replaceFirst("(?i)^Bearer\\s+", "").trim();
    }

    /** 校验是管理员（基于 permission 字段，0-管理员权限） */
    private void requireAdmin(String authorization) {
        String token = resolveToken(authorization);
        authService.requireAdmin(token);
    }

    // ============================ 1. 档案统计 ============================

    @GetMapping("/stats")
    public R<Map<String, Object>> stats(@RequestHeader(value = "Authorization", required = false) String authorization) {
        requireAdmin(authorization);

        LocalDateTime todayStart = LocalDate.now().atStartOfDay();
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total", archiveMapper.selectCount(null));
        data.put("publicArchives", archiveMapper.selectCount(new LambdaQueryWrapper<Archive>().eq(Archive::getVisibility, 1)));
        data.put("privateArchives", archiveMapper.selectCount(new LambdaQueryWrapper<Archive>().eq(Archive::getVisibility, 0)));
        data.put("todayNew", archiveMapper.selectCount(new LambdaQueryWrapper<Archive>().ge(Archive::getCreateTime, todayStart)));
        return R.ok("查询成功", data);
    }

    // ============================ 2. 档案列表 ============================

    /**
     * 跨所有用户查询档案（带所属用户名），支持关键词与可见性过滤。
     *
     * @param keyword    模糊匹配 标题 / 内容 / 标签
     * @param visibility 1-公开，0-仅自己，不传查全部
     */
    @GetMapping
    public R<Map<String, Object>> list(@RequestHeader(value = "Authorization", required = false) String authorization,
                                      @RequestParam(value = "keyword", required = false) String keyword,
                                      @RequestParam(value = "visibility", required = false) Integer visibility,
                                      @RequestParam(value = "page", defaultValue = "1") long page,
                                      @RequestParam(value = "size", defaultValue = "10") long size) {
        requireAdmin(authorization);

        if (page < 1) page = 1;
        if (size < 1 || size > 50) size = 10;
        String kw = StringUtils.hasText(keyword) ? keyword.trim() : null;

        long total = archiveMapper.countAdminList(kw, visibility);
        List<Map<String, Object>> records = archiveMapper.selectAdminList(kw, visibility, (page - 1) * size, size);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("total", total);
        data.put("page", page);
        data.put("size", size);
        data.put("records", records);
        return R.ok("查询成功", data);
    }

    // ============================ 3. 档案详情 ============================

    @GetMapping("/{id}")
    public R<Archive> detail(@RequestHeader(value = "Authorization", required = false) String authorization,
                             @PathVariable("id") Long id) {
        requireAdmin(authorization);
        Archive archive = requireArchive(id);
        return R.ok("查询成功", archive);
    }

    // ============================ 4. 编辑档案 ============================

    @PutMapping("/{id}")
    public R<Archive> update(@RequestHeader(value = "Authorization", required = false) String authorization,
                             @PathVariable("id") Long id,
                             @RequestBody ArchiveDTO dto) {
        requireAdmin(authorization);
        Archive archive = requireArchive(id);

        if (!StringUtils.hasText(dto.getTitle())) {
            throw new BusinessException("档案标题不能为空");
        }
        applyDto(archive, dto);
        archiveMapper.updateById(archive);

        log.info("管理员编辑档案 archiveId={}, ownerUserId={}, title={}", id, archive.getUserId(), archive.getTitle());
        return R.ok("档案已更新", archive);
    }

    // ============================ 5. 删除档案 ============================

    @DeleteMapping("/{id}")
    public R<Map<String, Object>> delete(@RequestHeader(value = "Authorization", required = false) String authorization,
                                         @PathVariable("id") Long id) {
        requireAdmin(authorization);
        Archive archive = requireArchive(id);
        archiveMapper.deleteById(id);

        log.info("管理员删除档案 archiveId={}, ownerUserId={}", id, archive.getUserId());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("id", id);
        return R.ok("档案已删除", data);
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
        if (StringUtils.hasText(dto.getTitle())) {
            archive.setTitle(dto.getTitle().trim());
        }
        if (dto.getContent() != null) {
            archive.setContent(dto.getContent().trim());
        }
        archive.setArchiveDate(parseDate(dto.getArchiveDate()));
        if (dto.getTag() != null) {
            archive.setTag(dto.getTag().trim());
        }
        if (dto.getVisibility() != null) {
            archive.setVisibility(dto.getVisibility() == 1 ? 1 : 0);
        }
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
}
