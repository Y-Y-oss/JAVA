package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 时光档案收藏实体，对应数据库中的 lc_archive_favorite 表
 * 同一用户对同一档案只能收藏一次（唯一键约束），再点一次 = 取消收藏。
 */
@Data
@TableName("lc_archive_favorite")
public class ArchiveFavorite implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 档案 id（lc_archive.id） */
    private Long archiveId;

    /** 收藏用户 id（lc_user.id） */
    private Long userId;

    /** 收藏时间 */
    private LocalDateTime createTime;
}
