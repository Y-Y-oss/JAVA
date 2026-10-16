package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 时光档案实体，对应数据库中的 lc_archive 表
 *
 * <p>「时光代理人」的核心业务：每位用户记录属于自己的时光档案
 * （一段回忆 / 一封信 / 一个约定），可选择是否公开到档案墙。</p>
 */
@Data
@TableName("lc_archive")
public class Archive implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 主键 */
    @TableId(type = IdType.AUTO)
    private Long id;

    /** 所属用户 id（lc_user.id） */
    private Long userId;

    /** 档案标题 */
    private String title;

    /** 档案内容 */
    private String content;

    /** 时光节点：这段回忆发生的日期 */
    private LocalDate archiveDate;

    /** 标签：如 私语/信件/告白/约定 */
    private String tag;

    /** 可见性：0-仅自己，1-公开到档案墙 */
    private Integer visibility;

    /** 创建时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
