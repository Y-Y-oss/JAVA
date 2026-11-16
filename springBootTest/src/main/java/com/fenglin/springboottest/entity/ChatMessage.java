package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 好友私信实体，对应数据库中的 lc_chat_message 表
 *
 * <p>一行表示一条一对一聊天消息。read_flag 以接收方视角为准：
 * 接收方打开与发送方的聊天窗口后置为 1。</p>
 */
@Data
@TableName("lc_chat_message")
public class ChatMessage implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 发送方用户 id */
    private Long senderId;

    /** 接收方用户 id */
    private Long receiverId;

    /** 消息内容（≤1000 字） */
    private String content;

    /** 已读状态：0-未读，1-已读 */
    private Integer readFlag;

    /** 发送时间 */
    private LocalDateTime createTime;
}
