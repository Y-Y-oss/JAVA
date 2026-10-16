package com.fenglin.springboottest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.io.Serializable;

/**
 * 修改密码请求参数：需要校验旧密码，改成功后密码版本号 +1，所有旧 token 立即失效
 */
@Data
public class ChangePasswordDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 当前密码 */
    @NotBlank(message = "请输入当前密码")
    private String oldPassword;

    /** 新密码 */
    @NotBlank(message = "请输入新密码")
    @Size(min = 6, max = 20, message = "密码需 6-20 位")
    private String newPassword;

    /** 确认新密码 */
    private String confirmPassword;
}
