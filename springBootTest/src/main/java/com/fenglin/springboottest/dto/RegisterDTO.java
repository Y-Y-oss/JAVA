package com.fenglin.springboottest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.io.Serializable;

/**
 * 注册请求参数
 *
 * <p>当前注册只需要「用户名 + 密码 + 图形验证码」；
 * 手机号已改为选填——留空即不绑定手机号，填了才做唯一性校验。</p>
 */
@Data
public class RegisterDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 用户名：2-20 位，字母/数字/下划线/中文 */
    @NotBlank(message = "请输入用户名")
    @Size(min = 2, max = 20, message = "用户名需 2-20 位")
    @Pattern(regexp = "^[\\u4e00-\\u9fa5a-zA-Z0-9_-]{2,20}$", message = "用户名只能包含中文、字母、数字、下划线或中划线")
    private String username;

    /** 手机号（选填，留空表示不绑定手机号） */
    @Pattern(regexp = "^$|^1[3-9]\\d{9}$", message = "请输入正确的 11 位手机号")
    private String phone;

    /** 图形验证码标识（调用 GET /api/auth/captcha 时下发） */
    @NotBlank(message = "请先获取图形验证码")
    private String captchaId;

    /** 图形验证码（用户看图输入，不区分大小写） */
    @NotBlank(message = "请输入图形验证码")
    private String captchaCode;

    /** 密码 */
    @NotBlank(message = "请输入密码")
    @Size(min = 6, max = 20, message = "密码需 6-20 位")
    private String password;

    /** 确认密码（前端第二次输入） */
    private String confirmPassword;
}
