package com.fenglin.springboottest.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.io.Serializable;
import java.time.LocalDateTime;

/**
 * 五子棋在线对局实体，对应数据库中的 lc_gomoku_game 表
 *
 * <p>board 为 15x15=225 字符的字符串：'0'空 / '1'黑 / '2'白，按 y*15+x 索引。
 * 双方前端各自轮询该行实现同步（本地演示项目不上 WebSocket）。</p>
 */
@Data
@TableName("lc_gomoku_game")
public class GomokuGame implements Serializable {

    private static final long serialVersionUID = 1L;

    @TableId(type = IdType.AUTO)
    private Long id;

    /** 黑方用户 id（先手） */
    private Long blackUserId;

    /** 白方用户 id */
    private Long whiteUserId;

    /** 邀请发起人 id */
    private Long hostUserId;

    /** 被邀请人 id */
    private Long guestUserId;

    /** 状态：0-等待接受，1-对弈中，2-已结束 */
    private Integer status;

    /** 棋盘 225 字符，0空1黑2白，按 y*15+x 索引 */
    private String board;

    /** 当前轮次：1-黑方，2-白方 */
    private Integer turn;

    /** 结果：0-未结束，1-黑胜，2-白胜，3-平局 */
    private Integer winner;

    /** 最后一手 x 坐标 */
    private Integer lastMoveX;

    /** 最后一手 y 坐标 */
    private Integer lastMoveY;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
