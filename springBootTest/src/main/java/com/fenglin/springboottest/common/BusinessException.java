package com.fenglin.springboottest.common;

import java.util.Map;

/**
 * 业务异常：提示信息会原样返回给前端
 */
public class BusinessException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    /** 可选：字段级错误信息 */
    private Map<String, String> errors;

    /** HTTP 状态码（用于区分 403 权限不足、401 未登录等语义） */
    private int code = 500;

    public BusinessException(String message) {
        super(message);
    }

    public BusinessException(int code, String message) {
        super(message);
        this.code = code;
    }

    public BusinessException(String message, Map<String, String> errors) {
        super(message);
        this.errors = errors;
    }

    public int getCode() {
        return code;
    }

    public Map<String, String> getErrors() {
        return errors;
    }

    public void setErrors(Map<String, String> errors) {
        this.errors = errors;
    }
}
