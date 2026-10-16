package com.fenglin.springboottest.common;

import io.jsonwebtoken.JwtException;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.validation.BindException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 全局异常处理：把各类异常统一转成前端能识别的 {code, message, errors} 结构
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    /**
     * 表单参数校验失败（@Validated / @Valid 触发）
     */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public R<Void> handleValidException(MethodArgumentNotValidException e) {
        Map<String, String> errors = new LinkedHashMap<>();
        for (FieldError fieldError : e.getBindingResult().getFieldErrors()) {
            errors.put(fieldError.getField(), fieldError.getDefaultMessage());
        }
        log.warn("参数校验失败: {}", errors);
        return R.fail("参数校验失败，请检查表单", errors);
    }

    @ExceptionHandler(BindException.class)
    public R<Void> handleBindException(BindException e) {
        Map<String, String> errors = new LinkedHashMap<>();
        for (FieldError fieldError : e.getBindingResult().getFieldErrors()) {
            errors.put(fieldError.getField(), fieldError.getDefaultMessage());
        }
        log.warn("参数绑定失败: {}", errors);
        return R.fail("参数校验失败，请检查表单", errors);
    }

    /**
     * 业务异常：携带明确提示，直接返回前端
     */
    @ExceptionHandler(BusinessException.class)
    public R<Void> handleBusinessException(BusinessException e) {
        log.warn("业务异常: {}", e.getMessage());
        return R.fail(e.getCode(), e.getMessage(), e.getErrors());
    }

    /**
     * JWT 相关异常：token 过期 / 签名错误 / 被篡改，统一提示重新登录
     */
    @ExceptionHandler(JwtException.class)
    public R<Void> handleJwtException(JwtException e) {
        log.warn("鉴权失败: {}", e.getMessage());
        return R.fail(401, "登录已过期或凭证无效，请重新登录");
    }

    /**
     * 其他未捕获异常
     */
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public R<Void> handleException(Exception e) {
        log.error("系统异常", e);
        return R.fail(500, "系统繁忙，请稍后再试");
    }
}
