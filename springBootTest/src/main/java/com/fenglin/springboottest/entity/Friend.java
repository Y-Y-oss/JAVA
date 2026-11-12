package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 好友关系实体，对应数据库中的 lc_friend 表
 *
 * <p>一行表示「user_id 向 friend_id 发出的关系」：
 * status=0 待对方验证，status=1 已同意。互为好友时双向各一行。</p>
 */
@Data
@TableName("lc_friend")
public class Friend implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 发起方用户 id（申请人） */
    private Long userId;

    /** 接收方用户 id（被添加人） */
    private Long friendId;

    /** 状态：0-待验证，1-已同意 */
    private Integer status;

    /** 发起/建立时间 */
    private LocalDateTime createTime;

    /** 更新时间 */
    private LocalDateTime updateTime;
}
