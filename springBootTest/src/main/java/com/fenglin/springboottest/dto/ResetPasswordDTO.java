package com.fenglin.springboottest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.io.Serializable;

/**
 * 重置密码请求参数
 *
 * <p>流程：手机号 → 获取重置验证码（scene=reset_password）→ 提交新密码。</p>
 */
@Data
public class ResetPasswordDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 手机号 */
    @NotBlank(message = "请输入手机号")
    @Pattern(regexp = "^1[3-9]\\d{9}$", message = "请输入正确的 11 位手机号")
    private String phone;

    /** 短信验证码（重置场景） */
    @NotBlank(message = "请输入验证码")
    @Pattern(regexp = "^\\d{6}$", message = "验证码为 6 位数字")
    private String code;

    /** 新密码 */
    @NotBlank(message = "请输入新密码")
    @Size(min = 6, max = 20, message = "密码需 6-20 位")
    private String password;

    /** 确认密码（前端第二次输入） */
    private String confirmPassword;
}
