package com.fenglin.springboottest.enums;

import java.util.Arrays;

/**
 * 用户角色。
 *
 * <p>角色以字符串形式存在 lc_user.role 里，签发 token 时也会写进 claim，
 * 接口校验时再用 {@link #matches(String...)} 判断。数据库里如果出现未知值，
 * 一律按普通用户处理（宁可最小权限）。</p>
 */
public enum UserRole {

    USER("user", "普通用户"),
    ADMIN("admin", "管理员");

    private final String code;
    private final String label;

    UserRole(String code, String label) {
        this.code = code;
        this.label = label;
    }

    public String getCode() {
        return code;
    }

    public String getLabel() {
        return label;
    }

    /**
     * 按存储值取角色，未知或为空时回退为普通用户
     */
    public static UserRole of(String code) {
        if (code == null || code.isEmpty()) {
            return USER;
        }
        return Arrays.stream(values())
                .filter(r -> r.code.equalsIgnoreCase(code.trim()))
                .findFirst()
                .orElse(USER);
    }

    /**
     * 是否命中给定角色之一
     */
    public boolean matches(String... codes) {
        if (codes == null || codes.length == 0) {
            return true;
        }
        return Arrays.stream(codes)
                .filter(c -> c != null && !c.isEmpty())
                .anyMatch(c -> c.equalsIgnoreCase(this.code));
    }
}
