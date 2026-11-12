package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 时光档案评论实体，对应数据库中的 lc_archive_comment 表
 */
@Data
@TableName("lc_archive_comment")
public class ArchiveComment implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 档案 id（lc_archive.id） */
    private Long archiveId;

    /** 评论用户 id（lc_user.id） */
    private Long userId;

    /** 评论内容（≤500 字） */
    private String content;

    /** 评论时间 */
    private LocalDateTime createTime;
}
