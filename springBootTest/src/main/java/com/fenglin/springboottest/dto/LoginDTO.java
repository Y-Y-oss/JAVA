package com.fenglin.springboottest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.io.Serializable;

/**
 * 登录请求参数（账号可以是用户名，也可以是手机号）
 */
@Data
public class LoginDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    @NotBlank(message = "请输入手机号或账号")
    @Size(min = 2, max = 30, message = "账号长度不合法")
    private String account;

    @NotBlank(message = "请输入密码")
    private String password;
}
