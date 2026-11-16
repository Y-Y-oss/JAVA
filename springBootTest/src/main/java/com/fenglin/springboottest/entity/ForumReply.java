package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 论坛回复实体，对应数据库中的 lc_forum_reply 表
 */
@Data
@TableName("lc_forum_reply")
public class ForumReply implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 所属帖子 id */
    private Long postId;

    /** 回复用户 id */
    private Long userId;

    /** 回复内容（≤500 字） */
    private String content;

    /** 回复时间 */
    private LocalDateTime createTime;
}
