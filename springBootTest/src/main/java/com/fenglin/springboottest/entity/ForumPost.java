package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 论坛帖子实体，对应数据库中的 lc_forum_post 表
 */
@Data
@TableName("lc_forum_post")
public class ForumPost implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 发帖用户 id */
    private Long userId;

    /** 帖子标题（≤100 字） */
    private String title;

    /** 帖子内容（≤3000 字） */
    private String content;

    /** 回复数（冗余字段，回复增删时同步维护） */
    private Integer replyCount;

    /** 发帖时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
