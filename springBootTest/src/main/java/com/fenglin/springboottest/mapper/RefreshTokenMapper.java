package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fenglin.springboottest.entity.RefreshToken;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 刷新令牌数据层
 */
public interface RefreshTokenMapper extends BaseMapper<RefreshToken> {

    /**
     * 按摘要查询（原始令牌经 SHA-256 后到这里定位）
     */
    @Select("SELECT * FROM lc_refresh_token WHERE token_hash = #{hash} LIMIT 1")
    RefreshToken selectByHash(@Param("hash") String hash);

    /**
     * 查询某用户在给定时刻之后仍然有效的令牌（用于批量吊销 / 登录后清理脏数据）
     */
    @Select("SELECT * FROM lc_refresh_token WHERE user_id = #{userId} AND expires_at > #{now} ORDER BY id DESC")
    List<RefreshToken> selectActiveByUserId(@Param("userId") Long userId, @Param("now") LocalDateTime now);

    /**
     * 查询同一令牌族下的全部记录（重放检测时整族作废）
     */
    @Select("SELECT * FROM lc_refresh_token WHERE family_id = #{familyId} ORDER BY id")
    List<RefreshToken> selectByFamilyId(@Param("familyId") String familyId);

    /**
     * 把某个令牌族下所有仍然有效的记录一次性吊销
     */
    @Update("UPDATE lc_refresh_token SET revoked = #{revoked}, revoked_reason = #{reason} " +
            "WHERE family_id = #{familyId} AND revoked = 0")
    int revokeFamily(@Param("familyId") String familyId, @Param("revoked") int revoked, @Param("reason") String reason);

    /**
     * 吊销某用户所有仍然有效的记录（登出 / 改密时调用）
     */
    @Update("UPDATE lc_refresh_token SET revoked = #{revoked}, revoked_reason = #{reason} " +
            "WHERE user_id = #{userId} AND revoked = 0")
    int revokeByUserId(@Param("userId") Long userId, @Param("revoked") int revoked, @Param("reason") String reason);

    /**
     * 清理已过期的记录（定时任务）
     */
    @Delete("DELETE FROM lc_refresh_token WHERE expires_at <= #{now}")
    int deleteExpired(@Param("now") LocalDateTime now);
}
