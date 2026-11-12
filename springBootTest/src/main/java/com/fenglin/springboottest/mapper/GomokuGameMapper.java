package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.GomokuGame;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

/**
 * 五子棋在线对局数据层
 */
public interface GomokuGameMapper extends BaseMapper<GomokuGame> {

    /** 对局详情（JOIN 出四方用户名），供"我的对局"列表与单局查询复用 */
    String DETAIL_COLUMNS =
            "g.id, g.black_user_id, g.white_user_id, g.host_user_id, g.guest_user_id, g.status, " +
            "g.board, g.turn, g.winner, g.last_move_x, g.last_move_y, g.create_time, g.update_time, " +
            "ub.username AS black_username, uw.username AS white_username, " +
            "uh.username AS host_username, ug.username AS guest_username ";

    String DETAIL_JOINS =
            "FROM lc_gomoku_game g " +
            "JOIN lc_user ub ON ub.id = g.black_user_id " +
            "JOIN lc_user uw ON uw.id = g.white_user_id " +
            "JOIN lc_user uh ON uh.id = g.host_user_id " +
            "JOIN lc_user ug ON ug.id = g.guest_user_id ";

    /** 单局详情（带四方位用户名） */
    @Select("SELECT " + DETAIL_COLUMNS + DETAIL_JOINS + "WHERE g.id = #{id}")
    Map<String, Object> selectGameDetail(@Param("id") Long id);

    /** 与我相关的全部对局（等待我接受 / 我等待对方 / 对弈中 / 已结束），按更新时间倒序 */
    @Select("SELECT " + DETAIL_COLUMNS + DETAIL_JOINS +
            "WHERE g.black_user_id = #{userId} OR g.white_user_id = #{userId} " +
            "OR g.guest_user_id = #{userId} " +
            "ORDER BY g.update_time DESC LIMIT 20")
    List<Map<String, Object>> selectMyGames(@Param("userId") Long userId);
}
