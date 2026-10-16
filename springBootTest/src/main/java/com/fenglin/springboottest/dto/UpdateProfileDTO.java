package com.fenglin.springboottest.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.io.Serializable;

/**
 * 修改个人资料请求参数
 *
 * <p>用户名和手机号是登录凭据，不允许在此改动（改手机号需要走验证码流程），这里只开放昵称。</p>
 */
@Data
public class UpdateProfileDTO implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 昵称：1-50 位 */
    @NotBlank(message = "请输入昵称")
    @Size(max = 50, message = "昵称最多 50 位")
    private String nickname;
}
