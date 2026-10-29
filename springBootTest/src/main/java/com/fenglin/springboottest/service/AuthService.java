package com.fenglin.springboottest.service;

import com.fenglin.springboottest.common.R;
import com.fenglin.springboottest.dto.ChangePasswordDTO;
import com.fenglin.springboottest.dto.LoginDTO;
import com.fenglin.springboottest.dto.RegisterDTO;
import com.fenglin.springboottest.dto.ResetPasswordDTO;
import com.fenglin.springboottest.dto.UpdateProfileDTO;
import com.fenglin.springboottest.entity.User;

import java.util.Map;

/**
 * 认证相关业务：短信验证码 + 用户注册 / 登录 / 重置密码
 */
public interface AuthService {

    /**
     * 发送短信验证码
     *
     * @param phone 手机号
     * @param scene 验证码场景，为空时使用默认场景（register）
     * @return 发送结果，data 中包含 expireSeconds / resendSeconds / code（演示模式下返回验证码）
     */
    R<Map<String, Object>> sendCode(String phone, String scene);

    /**
     * 重置密码：校验重置验证码后更新用户密码
     *
     * @param dto 重置密码参数
     * @return data 中包含 id / username / phone
     */
    R<Map<String, Object>> resetPassword(ResetPasswordDTO dto);

    /**
     * 注册
     *
     * @param dto 注册参数
     * @return 注册结果，data 中包含用户 id / username / phone
     */
    R<Map<String, Object>> register(RegisterDTO dto);

    /**
     * 登录：账号（用户名或手机号）+ 密码校验，校验通过签发 JWT
     *
     * @param dto 登录参数
     * @return data 中包含 token / tokenType / 用户信息
     */
    R<Map<String, Object>> login(LoginDTO dto);

    /**
     * 根据 token 获取当前登录用户
     *
     * @param token 不含 Bearer 前缀的 token 原文
     */
    R<Map<String, Object>> profile(String token);

    /**
     * 刷新令牌：校验通过后用「令牌轮换」方式签出一对新令牌
     *
     * @param refreshToken 刷新令牌原文（服务端只比对摘要）
     * @return data 中包含 accessToken / refreshToken / tokenType / expiresIn / refreshExpiresIn / 用户信息
     */
    R<Map<String, Object>> refresh(String refreshToken);

    /**
     * 退出登录：把当前 token 加入黑名单并吊销其刷新令牌
     */
    R<Map<String, Object>> logout(String token);

    /**
     * 修改个人资料（当前只开放昵称）
     */
    R<Map<String, Object>> updateProfile(String token, UpdateProfileDTO dto);

    /**
     * 修改密码：校验旧密码，成功后密码版本号 +1，旧 token 全部失效
     */
    R<Map<String, Object>> changePassword(String token, ChangePasswordDTO dto);

    /**
     * 角色校验：未登录会抛异常，角色不足时返回 403
     *
     * @param token          不含 Bearer 前缀的 token
     * @param requiredRoles  所需角色，为空表示「只要登录即可」
     */
    void checkRole(String token, String... requiredRoles);

    /**
     * 管理员鉴权：基于 permission 字段（0-管理员权限）校验当前登录用户。
     * 未登录 / 账号被禁用 / 权限不足（permission != 0）均会抛异常。
     *
     * @param token 不含 Bearer 前缀的 token
     * @return 通过校验的管理员用户实体
     */
    User requireAdmin(String token);
}
