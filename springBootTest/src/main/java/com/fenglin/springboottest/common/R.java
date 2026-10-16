package com.fenglin.springboottest.common;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.io.Serializable;
import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 统一返回结果封装
 *
 * @param <T> 返回数据类型
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public class R<T> implements Serializable {

    private static final long serialVersionUID = 1L;

    /** 业务状态码：200 成功，其余为失败码 */
    private int code;

    /** 提示信息，前端可直接展示给用户 */
    private String message;

    /** 业务数据 */
    private T data;

    /** 字段级校验错误：key 为表单字段名，value 为错误提示（可用于前端逐字段展示） */
    private Map<String, String> errors;

    public R() {
    }

    public R(int code, String message, T data) {
        this.code = code;
        this.message = message;
        this.data = data;
    }

    public static <T> R<T> ok(T data) {
        return new R<>(200, "操作成功", data);
    }

    public static <T> R<T> ok(String message, T data) {
        return new R<>(200, message, data);
    }

    public static <T> R<T> fail(String message) {
        return new R<>(500, message, null);
    }

    public static <T> R<T> fail(int code, String message) {
        return new R<>(code, message, null);
    }

    public static <T> R<T> fail(int code, String message, Map<String, String> errors) {
        R<T> r = new R<>(code, message, null);
        r.setErrors(errors);
        return r;
    }

    /**
     * 构造业务失败结果
     *
     * @param message 总体提示
     * @param errors  字段级错误
     */
    public static <T> R<T> fail(String message, Map<String, String> errors) {
        R<T> r = new R<>(500, message, null);
        r.setErrors(errors);
        return r;
    }

    public static Map<String, String> errors() {
        return new LinkedHashMap<>();
    }

    public int getCode() {
        return code;
    }

    public void setCode(int code) {
        this.code = code;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public T getData() {
        return data;
    }

    public void setData(T data) {
        this.data = data;
    }

    public Map<String, String> getErrors() {
        return errors;
    }

    public void setErrors(Map<String, String> errors) {
        this.errors = errors;
    }
}
