package com.fenglin.springboottest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 新建 / 编辑 时光档案的请求参数
 */
@Data
public class ArchiveDTO {

    /** 档案标题（必填，1-100 字） */
    @NotBlank(message = "请输入档案标题")
    @Size(max = 100, message = "标题最多 100 字")
    private String title;

    /** 档案内容（选填，最长 5000 字） */
    @Size(max = 5000, message = "内容最多 5000 字")
    private String content;

    /** 时光节点：回忆发生的日期，格式 yyyy-MM-dd（选填） */
    private String archiveDate;

    /** 标签（选填，最长 30 字） */
    @Size(max = 30, message = "标签最多 30 字")
    private String tag;

    /** 可见性：0-仅自己，1-公开到档案墙；不传默认 0 */
    private Integer visibility;
}
