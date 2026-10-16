-- =============================================================================
-- 时光代理人 · Link Click —— 注册功能 建库 / 建表 脚本
-- 数据库：link_click_auth
-- 数据库层：MyBatis-Plus（MySQL 8.x）
-- 执行方式（在 MySQL 客户端中执行本文件）：
--     mysql -uroot -p123456 < D:\workSpace\springBootTest\sql\link_click_auth.sql
-- 或：先 mysql -uroot -p123456，然后 source D:/workSpace/springBootTest/sql/link_click_auth.sql;
-- 说明：脚本可重复执行且不会破坏已有数据（用户表/档案表只在不存在时创建；
--       验证码表属临时数据，允许清空重建）。
-- =============================================================================

-- 1. 建库 --------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS `link_click_auth`
    DEFAULT CHARACTER SET `utf8mb4`
    DEFAULT COLLATE `utf8mb4_general_ci`;

USE `link_click_auth`;

-- 2. 用户表 ------------------------------------------------------------------
-- 对应实体：com.fenglin.springboottest.entity.User   （@TableName("lc_user")）
-- 只在不存在时创建，绝不 DROP，避免重跑脚本清空用户数据
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_user') = 0,
    'CREATE TABLE `lc_user`
(
    `id`         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT ''主键id'',
    `username`   VARCHAR(50)     NOT NULL                COMMENT ''用户名（唯一）'',
    `phone`      VARCHAR(20)     DEFAULT NULL            COMMENT ''手机号（选填，非空时唯一；MySQL 唯一索引允许存在多行 NULL）'',
    `password`   VARCHAR(100)    NOT NULL                COMMENT ''密码（BCrypt 哈希，不存明文）'',
    `nickname`   VARCHAR(50)     DEFAULT NULL            COMMENT ''昵称，默认与用户名一致'',
    `role`       VARCHAR(20)     NOT NULL DEFAULT ''user'' COMMENT ''角色：user-普通用户，admin-管理员'',
    `status`     TINYINT         NOT NULL DEFAULT 1      COMMENT ''账号状态：1-正常，0-禁用'',
    `pwd_version` INT            NOT NULL DEFAULT 1      COMMENT ''密码版本号：改密码时 +1，用于让所有旧 token 立即失效'',
    `last_login_time` DATETIME   NULL                    COMMENT ''最近一次登录时间'',
    `create_time` DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''创建时间'',
    `update_time` DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT ''更新时间'',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_lc_user_username` (`username`),
    UNIQUE KEY `uk_lc_user_phone` (`phone`),
    KEY `idx_lc_user_create_time` (`create_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = ''时光代理人-用户表''',
    'SELECT ''lc_user 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. 短信验证码表 ------------------------------------------------------------
-- 对应实体：com.fenglin.springboottest.entity.SmsCode   （@TableName("lc_sms_code")）
DROP TABLE IF EXISTS `lc_sms_code`;

CREATE TABLE `lc_sms_code`
(
    `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
    `phone`       VARCHAR(20)     NOT NULL                COMMENT '手机号',
    `code`        VARCHAR(10)     NOT NULL                COMMENT '验证码',
    `scene`       VARCHAR(20)     NOT NULL DEFAULT 'register' COMMENT '验证码场景：register-注册，reset_password-重置密码',
    `expire_time` DATETIME        NOT NULL                COMMENT '过期时间',
    `consumed`    TINYINT         NOT NULL DEFAULT 0      COMMENT '是否已使用：0-未使用，1-已使用',
    `create_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (`id`),
    KEY `idx_lc_sms_code_phone_scene` (`phone`, `scene`, `create_time`),
    KEY `idx_lc_sms_code_expire_time` (`expire_time`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '时光代理人-短信验证码表';

-- 4. 刷新令牌表（双令牌方案）--------------------------------------------------
-- 对应实体：com.fenglin.springboottest.entity.RefreshToken   （@TableName("lc_refresh_token")）
DROP TABLE IF EXISTS `lc_refresh_token`;

CREATE TABLE `lc_refresh_token`
(
    `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
    `user_id`        BIGINT UNSIGNED NOT NULL                COMMENT '所属用户 id',
    `token_hash`     CHAR(64)        NOT NULL                COMMENT '刷新令牌的 SHA-256 摘要（原始令牌只存前端，库里不落明文）',
    `family_id`      VARCHAR(36)     NOT NULL                COMMENT '令牌族：同族令牌成链轮换，整族作废时一次性吊销',
    `expires_at`     DATETIME        NOT NULL                COMMENT '过期时间',
    `revoked`        TINYINT         NOT NULL DEFAULT 0      COMMENT '吊销状态：0-有效，1-已轮换（正常），2-已吊销（登出/重放）',
    `revoked_reason` VARCHAR(32)     DEFAULT NULL            COMMENT '吊销原因：rotate-正常轮换 / logout-主动登出 / replay-重放检测 / expired-过期清理',
    `replaced_by`    CHAR(64)        DEFAULT NULL            COMMENT '轮换后接替它的令牌摘要，可沿链追溯整条会话',
    `create_time`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    UNIQUE KEY `uk_lc_refresh_token_hash` (`token_hash`),
    KEY `idx_lc_refresh_token_user` (`user_id`),
    KEY `idx_lc_refresh_token_family` (`family_id`),
    KEY `idx_lc_refresh_token_expire` (`expires_at`)
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4
  COLLATE = utf8mb4_general_ci
  COMMENT = '时光代理人-刷新令牌表（双令牌方案）';

-- 5. 演示数据（可选，方便本地验证登录/注册）------------------------------------
-- 注意：下面密码明文为 123456，已用 BCrypt 生成（$2a$10$ 开头），可直接插入。
-- INSERT INTO `lc_user` (`username`, `phone`, `password`, `nickname`)
-- VALUES ('linkclick', '13800000000',
--         '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi',
--         '时光代理人');

-- 6. 增量升级（已建过表时执行，可重复运行）--------------------------------------
-- 给早期建好的 lc_user 补上 last_login_time 列（用 information_schema 判断，避免重复添加报错）
SET @exist := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_user' AND COLUMN_NAME = 'last_login_time'
);
SET @sql := IF(@exist = 0,
    'ALTER TABLE `lc_user` ADD COLUMN `last_login_time` DATETIME NULL COMMENT ''最近一次登录时间'' AFTER `status`',
    'SELECT ''lc_user.last_login_time 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 给早期建好的 lc_user 补上 pwd_version 列（用于「修改密码后所有旧 token 立即失效」）
SET @exist := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_user' AND COLUMN_NAME = 'pwd_version'
);
SET @sql := IF(@exist = 0,
    'ALTER TABLE `lc_user` ADD COLUMN `pwd_version` INT NOT NULL DEFAULT 1 COMMENT ''密码版本号：改密码时 +1'' AFTER `status`',
    'SELECT ''lc_user.pwd_version 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 给早期建好的 lc_user 补上 role 列（角色：user-普通用户，admin-管理员）
SET @exist := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_user' AND COLUMN_NAME = 'role'
);
SET @sql := IF(@exist = 0,
    'ALTER TABLE `lc_user` ADD COLUMN `role` VARCHAR(20) NOT NULL DEFAULT ''user'' COMMENT ''角色：user-普通用户，admin-管理员'' AFTER `nickname`',
    'SELECT ''lc_user.role 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 为早期未建过刷新令牌表的实例补表（可重复运行）
SET @exist := (
    SELECT COUNT(*) FROM information_schema.TABLES
    WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_refresh_token'
);
SET @sql := IF(@exist = 0,
    'CREATE TABLE `lc_refresh_token` (
        `id`             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
        `user_id`        BIGINT UNSIGNED NOT NULL,
        `token_hash`     CHAR(64)        NOT NULL,
        `family_id`      VARCHAR(36)     NOT NULL,
        `expires_at`     DATETIME        NOT NULL,
        `revoked`        TINYINT         NOT NULL DEFAULT 0,
        `revoked_reason` VARCHAR(32)     DEFAULT NULL,
        `replaced_by`    CHAR(64)        DEFAULT NULL,
        `create_time`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
        `update_time`    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_lc_refresh_token_hash` (`token_hash`),
        KEY `idx_lc_refresh_token_user` (`user_id`),
        KEY `idx_lc_refresh_token_family` (`family_id`),
        KEY `idx_lc_refresh_token_expire` (`expires_at`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
      COMMENT = ''时光代理人-刷新令牌表（双令牌方案）''',
    'SELECT ''lc_refresh_token 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 7. 常用维护语句 ------------------------------------------------------------
-- 清空验证码表：DELETE FROM `lc_sms_code`;
-- 查看注册用户：SELECT id, username, role, status, create_time FROM `lc_user`;
-- 把某个账号提为管理员（演示「权限不足」用）：
-- UPDATE `lc_user` SET `role` = 'admin' WHERE `username` = 'lc_demo';
-- 查看当前生效的会话：SELECT user_id, family_id, revoked, revoked_reason, expires_at FROM `lc_refresh_token` WHERE revoked = 0;
-- 手动吊销某用户所有会话：UPDATE `lc_refresh_token` SET revoked = 2, revoked_reason = 'manual' WHERE user_id = 1 AND revoked = 0;

-- 8. 时光档案表 ----------------------------------------------------------------
-- 对应实体：com.fenglin.springboottest.entity.Archive （@TableName("lc_archive")）
-- 用可重复执行的方式建表：已存在则跳过（不 DROP，避免误删用户档案数据）
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_archive') = 0,
    'CREATE TABLE `lc_archive` (
        `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT ''主键id'',
        `user_id`      BIGINT UNSIGNED NOT NULL                COMMENT ''所属用户id（lc_user.id）'',
        `title`        VARCHAR(100)    NOT NULL                COMMENT ''档案标题'',
        `content`      TEXT                                    COMMENT ''档案内容'',
        `archive_date` DATE            DEFAULT NULL            COMMENT ''时光节点：这段回忆发生的日期'',
        `tag`          VARCHAR(30)     DEFAULT NULL            COMMENT ''标签：如 私语/信件/告白/约定'',
        `visibility`   TINYINT         NOT NULL DEFAULT 0      COMMENT ''可见性：0-仅自己，1-公开到档案墙'',
        `create_time`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''创建时间'',
        `update_time`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT ''更新时间'',
        PRIMARY KEY (`id`),
        KEY `idx_lc_archive_user` (`user_id`),
        KEY `idx_lc_archive_public` (`visibility`, `update_time`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
      COMMENT = ''时光代理人-时光档案表''',
    'SELECT ''lc_archive 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
