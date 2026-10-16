package com.fenglin.springboottest.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.fenglin.springboottest.entity.SmsCode;
import org.apache.ibatis.annotations.Param;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 短信验证码数据层
 */
public interface SmsCodeMapper extends BaseMapper<SmsCode> {

    /**
     * 查询某手机号在某个场景下、指定时间之后生成的、尚未使用的验证码（按时间倒序取最新一条）
     */
    default SmsCode selectLatestValid(@Param("phone") String phone,
                                     @Param("scene") String scene,
                                     @Param("minCreateTime") LocalDateTime minCreateTime,
                                     @Param("consumed") Integer consumed) {
        LambdaQueryWrapper<SmsCode> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SmsCode::getPhone, phone)
                .eq(SmsCode::getScene, scene)
                .eq(SmsCode::getConsumed, consumed)
                .gt(SmsCode::getCreateTime, minCreateTime)
                .orderByDesc(SmsCode::getId)
                .last("LIMIT 1");
        return selectOne(wrapper);
    }

    /**
     * 清理某手机号在某个场景下的历史验证码
     */
    default int deleteByPhoneAndScene(@Param("phone") String phone, @Param("scene") String scene) {
        LambdaQueryWrapper<SmsCode> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SmsCode::getPhone, phone).eq(SmsCode::getScene, scene);
        return delete(wrapper);
    }

    /**
     * 查询最近生成的验证码（用于验证码防刷：限制发送频率）
     */
    default List<SmsCode> selectRecent(@Param("phone") String phone,
                                       @Param("scene") String scene,
                                       @Param("minCreateTime") LocalDateTime minCreateTime) {
        LambdaQueryWrapper<SmsCode> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(SmsCode::getPhone, phone)
                .eq(SmsCode::getScene, scene)
                .gt(SmsCode::getCreateTime, minCreateTime)
                .orderByDesc(SmsCode::getId)
                .last("LIMIT 5");
        return selectList(wrapper);
    }
}
