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
    `password`   VARCHAR(100)    NOT NULL                COMMENT ''密码（明文存储，按需求不加密）'',
    `nickname`   VARCHAR(50)     DEFAULT NULL            COMMENT ''昵称，默认与用户名一致'',
    `role`       VARCHAR(20)     NOT NULL DEFAULT ''user'' COMMENT ''角色：user-普通用户，admin-管理员'',
    `status`     TINYINT         NOT NULL DEFAULT 1      COMMENT ''账号状态：1-正常，0-禁用'',
    `pwd_version` INT            NOT NULL DEFAULT 1      COMMENT ''密码版本号：改密码时 +1，用于让所有旧 token 立即失效'',
    `last_login_time` DATETIME   NULL                    COMMENT ''最近一次登录时间'',
    `create_time` DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''创建时间'',
    `update_time` DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT ''更新时间'',
    `permission` TINYINT         NOT NULL DEFAULT 1      COMMENT ''权限：1-默认权限（普通用户），0-管理员权限（可进入后台管理系统）'',
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
-- 注意：按需求密码以明文存储（不加密）。下面示例密码为明文 123456。
-- INSERT INTO `lc_user` (`username`, `phone`, `password`, `nickname`, `role`, `permission`)
-- VALUES ('linkclick', '13800000000', '123456', '时光代理人', 'user', 1);

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

-- 给早期建好的 lc_user 补上 permission 列（权限：1-默认权限，0-管理员权限）
SET @exist := (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_user' AND COLUMN_NAME = 'permission'
);
SET @sql := IF(@exist = 0,
    'ALTER TABLE `lc_user` ADD COLUMN `permission` TINYINT NOT NULL DEFAULT 1 COMMENT ''权限：1-默认权限（普通用户），0-管理员权限（可进入后台管理系统）'' AFTER `update_time`',
    'SELECT ''lc_user.permission 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 让 permission 与 role 对齐：admin 角色 -> 0（管理员权限），其余 -> 1（默认权限）
UPDATE `lc_user` SET `permission` = 0 WHERE `role` = 'admin' AND (`permission` IS NULL OR `permission` <> 0);
UPDATE `lc_user` SET `permission` = 1 WHERE (`role` IS NULL OR `role` <> 'admin') AND (`permission` IS NULL OR `permission` <> 1);

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
-- 把某个账号提为管理员（演示「权限不足」用）：role 与 permission 需同时设置
-- UPDATE `lc_user` SET `role` = 'admin', `permission` = 0 WHERE `username` = 'lc_demo';
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
        `cover`        VARCHAR(512)    DEFAULT NULL            COMMENT ''封面照片地址（用户上传后返回的相对路径，如 /uploads/archives/xxx.png）'',
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

-- 9. 登录日志表 ----------------------------------------------------------------
-- 对应实体：com.fenglin.springboottest.entity.LoginLog （@TableName("lc_login_log")）
-- 用可重复执行的方式建表：已存在则跳过（不 DROP，登录历史是永久审计数据，绝不能清空）。
-- 与 lc_user.last_login_time（仅保留「最近一次」快查字段）不同，本表每次登录都「追加」一条记录。
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_login_log') = 0,
    'CREATE TABLE `lc_login_log` (
        `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT ''主键id'',
        `user_id`      BIGINT UNSIGNED DEFAULT NULL            COMMENT ''登录用户id（登录失败且账号不存在时为 NULL）'',
        `username`     VARCHAR(50)     NOT NULL                COMMENT ''登录时使用的账号名（成功/失败都记录，便于审计）'',
        `login_type`   VARCHAR(20)     NOT NULL DEFAULT ''password'' COMMENT ''登录方式：password-账号密码'',
        `ip`           VARCHAR(64)     DEFAULT NULL            COMMENT ''登录来源 IP（已处理 X-Forwarded-For）'',
        `user_agent`   VARCHAR(512)    DEFAULT NULL            COMMENT ''客户端 User-Agent'',
        `success`      TINYINT         NOT NULL DEFAULT 1      COMMENT ''是否成功：1-成功，0-失败'',
        `fail_reason`  VARCHAR(64)     DEFAULT NULL            COMMENT ''失败原因：账号不存在/已禁用、密码错误、参数缺失'',
        `login_time`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''登录发生时间'',
        `create_time`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''记录创建时间'',
        PRIMARY KEY (`id`),
        KEY `idx_lc_login_log_user` (`user_id`),
        KEY `idx_lc_login_log_success` (`success`),
        KEY `idx_lc_login_log_time` (`login_time`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
      COMMENT = ''时光代理人-登录日志表（每次登录追加一条，永不覆盖）''',
    'SELECT ''lc_login_log 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 10. 档案点赞表 ----------------------------------------------------------------
-- 对应实体：com.fenglin.springboottest.entity.ArchiveLike （@TableName("lc_archive_like")）
-- 已存在则跳过（不 DROP）。唯一键保证一人一档只能赞一次，重复点赞=取消。
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_archive_like') = 0,
    'CREATE TABLE `lc_archive_like` (
        `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT ''主键id'',
        `archive_id`  BIGINT UNSIGNED NOT NULL                COMMENT ''档案id（lc_archive.id）'',
        `user_id`     BIGINT UNSIGNED NOT NULL                COMMENT ''点赞用户id（lc_user.id）'',
        `create_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''点赞时间'',
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_like_archive_user` (`archive_id`, `user_id`),
        KEY `idx_like_user` (`user_id`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
      COMMENT = ''时光代理人-档案点赞表''',
    'SELECT ''lc_archive_like 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 11. 档案收藏表 ----------------------------------------------------------------
-- 对应实体：com.fenglin.springboottest.entity.ArchiveFavorite （@TableName("lc_archive_favorite")）
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_archive_favorite') = 0,
    'CREATE TABLE `lc_archive_favorite` (
        `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT ''主键id'',
        `archive_id`  BIGINT UNSIGNED NOT NULL                COMMENT ''档案id（lc_archive.id）'',
        `user_id`     BIGINT UNSIGNED NOT NULL                COMMENT ''收藏用户id（lc_user.id）'',
        `create_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''收藏时间'',
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_fav_archive_user` (`archive_id`, `user_id`),
        KEY `idx_fav_user` (`user_id`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
      COMMENT = ''时光代理人-档案收藏表''',
    'SELECT ''lc_archive_favorite 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 12. 档案评论表 ----------------------------------------------------------------
-- 对应实体：com.fenglin.springboottest.entity.ArchiveComment （@TableName("lc_archive_comment")）
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_archive_comment') = 0,
    'CREATE TABLE `lc_archive_comment` (
        `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT ''主键id'',
        `archive_id`  BIGINT UNSIGNED NOT NULL                COMMENT ''档案id（lc_archive.id）'',
        `user_id`     BIGINT UNSIGNED NOT NULL                COMMENT ''评论用户id（lc_user.id）'',
        `content`     VARCHAR(500)    NOT NULL                COMMENT ''评论内容（≤500字）'',
        `create_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''评论时间'',
        PRIMARY KEY (`id`),
        KEY `idx_comment_archive` (`archive_id`, `create_time`),
        KEY `idx_comment_user` (`user_id`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
      COMMENT = ''时光代理人-档案评论表''',
    'SELECT ''lc_archive_comment 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 13. 好友关系表 ----------------------------------------------------------------
-- 对应实体：com.fenglin.springboottest.entity.Friend （@TableName("lc_friend")）
-- 同一行表示「user_id 向 friend_id 发出的关系」：status=0 待验证，1 已同意（互为好友时双向各一行）。
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_friend') = 0,
    'CREATE TABLE `lc_friend` (
        `id`          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT ''主键id'',
        `user_id`     BIGINT UNSIGNED NOT NULL                COMMENT ''发起方用户id（申请人）'',
        `friend_id`   BIGINT UNSIGNED NOT NULL                COMMENT ''接收方用户id（被添加人）'',
        `status`      TINYINT         NOT NULL DEFAULT 0      COMMENT ''状态：0-待验证，1-已同意'',
        `create_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''发起/建立时间'',
        `update_time` DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT ''更新时间'',
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_friend_pair` (`user_id`, `friend_id`),
        KEY `idx_friend_target` (`friend_id`, `status`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
      COMMENT = ''时光代理人-好友关系表（同意后双向各一行）''',
    'SELECT ''lc_friend 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 14. 五子棋在线对局表 ----------------------------------------------------------------
-- 对应实体：com.fenglin.springboottest.entity.GomokuGame （@TableName("lc_gomoku_game")）
-- board 为 15x15=225 字符的字符串，'0'空 '1'黑 '2'白，按 y*15+x 索引；双方前端轮询同步。
SET @sql = IF(
    (SELECT COUNT(*) FROM information_schema.TABLES
      WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_gomoku_game') = 0,
    'CREATE TABLE `lc_gomoku_game` (
        `id`            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT ''对局id'',
        `black_user_id` BIGINT UNSIGNED NOT NULL                COMMENT ''黑方用户id（先手）'',
        `white_user_id` BIGINT UNSIGNED NOT NULL                COMMENT ''白方用户id'',
        `host_user_id`  BIGINT UNSIGNED NOT NULL                COMMENT ''邀请发起人id'',
        `guest_user_id` BIGINT UNSIGNED NOT NULL                COMMENT ''被邀请人id'',
        `status`        TINYINT         NOT NULL DEFAULT 0      COMMENT ''状态：0-等待接受，1-对弈中，2-已结束'',
        `board`         VARCHAR(225)    NOT NULL                COMMENT ''棋盘225字符，0空1黑2白，按y*15+x索引'',
        `turn`          TINYINT         NOT NULL DEFAULT 1      COMMENT ''当前轮次：1-黑方，2-白方'',
        `winner`        TINYINT         NOT NULL DEFAULT 0      COMMENT ''结果：0-未结束，1-黑胜，2-白胜，3-平局'',
        `last_move_x`   TINYINT         DEFAULT NULL            COMMENT ''最后一手x坐标'',
        `last_move_y`   TINYINT         DEFAULT NULL            COMMENT ''最后一手y坐标'',
        `create_time`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT ''创建时间'',
        `update_time`   DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT ''更新时间'',
        PRIMARY KEY (`id`),
        KEY `idx_gomoku_black` (`black_user_id`),
        KEY `idx_gomoku_white` (`white_user_id`),
        KEY `idx_gomoku_guest` (`guest_user_id`, `status`)
    ) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_general_ci
      COMMENT = ''时光代理人-五子棋在线对局表''',
    'SELECT ''lc_gomoku_game 已存在，跳过''');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 15. 用户头像列 ----------------------------------------------------------------
-- 给早期建好的 lc_user 补上 avatar 列（用户上传的头像相对路径，如 /uploads/avatars/xxx.png）
SET @col = IF(
    (SELECT COUNT(*) FROM information_schema.COLUMNS
      WHERE TABLE_SCHEMA = 'link_click_auth' AND TABLE_NAME = 'lc_user' AND COLUMN_NAME = 'avatar') = 0,
    'ALTER TABLE `lc_user` ADD COLUMN `avatar` VARCHAR(512) DEFAULT NULL COMMENT ''头像地址（用户上传后的相对路径；空则用首字母默认头像）'' AFTER `nickname`',
    'SELECT ''lc_user.avatar 已存在，跳过''');
PREPARE stmt FROM @col;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
