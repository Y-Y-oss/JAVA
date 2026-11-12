/*
 Navicat Premium Dump SQL

 Source Server         : test
 Source Server Type    : MySQL
 Source Server Version : 80039 (8.0.39)
 Source Host           : localhost:3306
 Source Schema         : link_click_auth

 Target Server Type    : MySQL
 Target Server Version : 80039 (8.0.39)
 File Encoding         : 65001

 Date: 12/11/2026 15:12:30
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for lc_archive
-- ----------------------------
DROP TABLE IF EXISTS `lc_archive`;
CREATE TABLE `lc_archive`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` bigint UNSIGNED NOT NULL COMMENT '所属用户id（lc_user.id）',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '档案标题',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL COMMENT '档案内容',
  `archive_date` date NULL DEFAULT NULL COMMENT '时光节点：这段回忆发生的日期',
  `tag` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '标签：如 私语/信件/告白/约定',
  `cover` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '封面照片地址',
  `visibility` tinyint NOT NULL DEFAULT 0 COMMENT '可见性：0-仅自己，1-公开到档案墙',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_lc_archive_user`(`user_id` ASC) USING BTREE,
  INDEX `idx_lc_archive_public`(`visibility` ASC, `update_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 10004 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-时光档案表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_archive
-- ----------------------------
INSERT INTO `lc_archive` VALUES (1, 1, '雨中私语', '那是 2019 年的春天，一场突如其来的雨把我们困在便利店屋檐下。你递来半杯热可可，雨声里我们谁都没有多说话，却记了很久。', '2019-04-12', '私语', NULL, 1, '2026-10-09 15:00:00', '2026-10-09 15:00:00');
INSERT INTO `lc_archive` VALUES (2, 1, '未寄出的信', '写给三年前的你：有些话当时没敢说出口，后来发现，不说也挺好。这封信就留在抽屉里，当作一段没说完的时光。', '2021-07-08', '信件', NULL, 1, '2026-10-09 15:05:00', '2026-10-09 15:05:00');
INSERT INTO `lc_archive` VALUES (3, 1, '天台上的告白', '跨年钟声倒数到三的时候，你突然说喜欢我。烟火在头顶炸开，我愣了三秒才回过神来。', '2019-12-24', '告白', NULL, 1, '2026-10-09 15:10:00', '2026-10-09 15:10:00');
INSERT INTO `lc_archive` VALUES (4, 1, '跨年烟火下的约定', '我们说好每一年跨年都要在同一个地方见面，看同一场烟火。今年是你缺席的第一年。', '2020-12-31', '约定', NULL, 1, '2026-10-09 15:15:00', '2026-10-09 15:15:00');
INSERT INTO `lc_archive` VALUES (5, 1, '旧巷口的猫', '巷口那只橘猫又生了三宝，路过时它还是会蹭我的裤脚。有些陪伴不需要名字，也不需要结局。', '2022-03-15', '私语', NULL, 0, '2026-10-09 15:20:00', '2026-10-09 15:20:00');
INSERT INTO `lc_archive` VALUES (6, 1, '雨夜便利店', '加班到凌晨，便利店的关东煮和那首老歌，是这座城市留给独行人的温柔。', '2023-06-02', '私语', NULL, 0, '2026-10-09 15:25:00', '2026-10-09 15:25:00');
INSERT INTO `lc_archive` VALUES (7, 2, '1', NULL, '2026-10-28', '私语', NULL, 1, '2026-10-28 16:25:20', '2026-10-28 16:25:20');
INSERT INTO `lc_archive` VALUES (8, 2, '未寄出的信', NULL, '2026-10-28', '私语', NULL, 0, '2026-10-28 16:25:54', '2026-10-28 16:25:54');
INSERT INTO `lc_archive` VALUES (9, 2, '旧巷口的猫', NULL, '2026-10-28', '私语', NULL, 0, '2026-10-28 16:39:15', '2026-10-28 16:39:15');
INSERT INTO `lc_archive` VALUES (10, 2, '雨夜便利店', NULL, '2026-10-28', '私语', NULL, 1, '2026-10-28 16:39:45', '2026-10-28 16:39:45');
INSERT INTO `lc_archive` VALUES (11, 2, '跨年烟火下的约定', NULL, '2026-10-28', '私语', NULL, 0, '2026-10-28 16:40:04', '2026-10-28 16:40:04');
INSERT INTO `lc_archive` VALUES (12, 2, '雨中私语', NULL, '2026-10-28', '私语', NULL, 0, '2026-10-28 16:41:09', '2026-10-28 16:41:09');
INSERT INTO `lc_archive` VALUES (13, 4, '1', NULL, '2026-10-28', '私语', NULL, 0, '2026-10-28 23:10:32', '2026-10-28 23:10:32');
INSERT INTO `lc_archive` VALUES (14, 4, '2', NULL, '2026-10-28', '私语', NULL, 1, '2026-10-28 23:10:44', '2026-10-28 23:10:44');
INSERT INTO `lc_archive` VALUES (10000, 2, 'a', NULL, '2026-11-06', '私语', NULL, 0, '2026-11-06 14:04:07', '2026-11-06 14:04:07');
INSERT INTO `lc_archive` VALUES (10001, 2, 'b', NULL, '2026-11-06', '约定', NULL, 0, '2026-11-06 14:18:19', '2026-11-06 14:18:19');
INSERT INTO `lc_archive` VALUES (10002, 29, '上传测试档案', '验证照片上传与社区互动', NULL, NULL, '/uploads/archives/2949b4027ccd4d3ca1576c01e1df03ed.png', 1, '2026-11-12 14:13:30', '2026-11-12 14:13:30');
INSERT INTO `lc_archive` VALUES (10003, 2, '1', NULL, '2026-11-12', '告白', '/uploads/archives/d89e47bf8138479cbc1eac2d3cdd8c74.jpg', 1, '2026-11-12 14:15:18', '2026-11-12 14:15:18');

-- ----------------------------
-- Table structure for lc_archive_comment
-- ----------------------------
DROP TABLE IF EXISTS `lc_archive_comment`;
CREATE TABLE `lc_archive_comment`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `archive_id` bigint UNSIGNED NOT NULL COMMENT '档案id（lc_archive.id）',
  `user_id` bigint UNSIGNED NOT NULL COMMENT '评论用户id（lc_user.id）',
  `content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '评论内容（≤500字）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '评论时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_comment_archive`(`archive_id` ASC, `create_time` ASC) USING BTREE,
  INDEX `idx_comment_user`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-档案评论表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of lc_archive_comment
-- ----------------------------
INSERT INTO `lc_archive_comment` VALUES (2, 10003, 2, 'ggsyeyeri', '2026-11-12 14:16:19');

-- ----------------------------
-- Table structure for lc_archive_favorite
-- ----------------------------
DROP TABLE IF EXISTS `lc_archive_favorite`;
CREATE TABLE `lc_archive_favorite`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `archive_id` bigint UNSIGNED NOT NULL COMMENT '档案id（lc_archive.id）',
  `user_id` bigint UNSIGNED NOT NULL COMMENT '收藏用户id（lc_user.id）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_fav_archive_user`(`archive_id` ASC, `user_id` ASC) USING BTREE,
  INDEX `idx_fav_user`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-档案收藏表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of lc_archive_favorite
-- ----------------------------
INSERT INTO `lc_archive_favorite` VALUES (1, 10002, 29, '2026-11-12 14:13:49');

-- ----------------------------
-- Table structure for lc_archive_like
-- ----------------------------
DROP TABLE IF EXISTS `lc_archive_like`;
CREATE TABLE `lc_archive_like`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `archive_id` bigint UNSIGNED NOT NULL COMMENT '档案id（lc_archive.id）',
  `user_id` bigint UNSIGNED NOT NULL COMMENT '点赞用户id（lc_user.id）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '点赞时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_like_archive_user`(`archive_id` ASC, `user_id` ASC) USING BTREE,
  INDEX `idx_like_user`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-档案点赞表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of lc_archive_like
-- ----------------------------
INSERT INTO `lc_archive_like` VALUES (2, 10002, 29, '2026-11-12 14:14:07');

-- ----------------------------
-- Table structure for lc_friend
-- ----------------------------
DROP TABLE IF EXISTS `lc_friend`;
CREATE TABLE `lc_friend`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` bigint UNSIGNED NOT NULL COMMENT '发起方用户id（申请人）',
  `friend_id` bigint UNSIGNED NOT NULL COMMENT '接收方用户id（被添加人）',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态：0-待验证，1-已同意',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发起/建立时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_friend_pair`(`user_id` ASC, `friend_id` ASC) USING BTREE,
  INDEX `idx_friend_target`(`friend_id` ASC, `status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 6 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-好友关系表（同意后双向各一行）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of lc_friend
-- ----------------------------
INSERT INTO `lc_friend` VALUES (1, 29, 30, 1, '2026-11-12 14:39:24', '2026-11-12 14:39:24');
INSERT INTO `lc_friend` VALUES (2, 30, 29, 1, '2026-11-12 14:39:25', '2026-11-12 14:39:25');
INSERT INTO `lc_friend` VALUES (3, 2, 4, 1, '2026-11-12 14:41:28', '2026-11-12 14:41:28');
INSERT INTO `lc_friend` VALUES (4, 4, 2, 1, '2026-11-12 14:41:46', '2026-11-12 14:41:46');
INSERT INTO `lc_friend` VALUES (5, 2, 1, 0, '2026-11-12 14:52:32', '2026-11-12 14:52:32');

-- ----------------------------
-- Table structure for lc_gomoku_game
-- ----------------------------
DROP TABLE IF EXISTS `lc_gomoku_game`;
CREATE TABLE `lc_gomoku_game`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '对局id',
  `black_user_id` bigint UNSIGNED NOT NULL COMMENT '黑方用户id（先手）',
  `white_user_id` bigint UNSIGNED NOT NULL COMMENT '白方用户id',
  `host_user_id` bigint UNSIGNED NOT NULL COMMENT '邀请发起人id',
  `guest_user_id` bigint UNSIGNED NOT NULL COMMENT '被邀请人id',
  `status` tinyint NOT NULL DEFAULT 0 COMMENT '状态：0-等待接受，1-对弈中，2-已结束',
  `board` varchar(225) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '棋盘225字符，0空1黑2白，按y*15+x索引',
  `turn` tinyint NOT NULL DEFAULT 1 COMMENT '当前轮次：1-黑方，2-白方',
  `winner` tinyint NOT NULL DEFAULT 0 COMMENT '结果：0-未结束，1-黑胜，2-白胜，3-平局',
  `last_move_x` tinyint NULL DEFAULT NULL COMMENT '最后一手x坐标',
  `last_move_y` tinyint NULL DEFAULT NULL COMMENT '最后一手y坐标',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_gomoku_black`(`black_user_id` ASC) USING BTREE,
  INDEX `idx_gomoku_white`(`white_user_id` ASC) USING BTREE,
  INDEX `idx_gomoku_guest`(`guest_user_id` ASC, `status` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-五子棋在线对局表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of lc_gomoku_game
-- ----------------------------
INSERT INTO `lc_gomoku_game` VALUES (2, 29, 30, 29, 30, 2, '111110000000000222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 1, 2, 4, 1, '2026-11-12 14:42:09', '2026-11-12 14:42:09');
INSERT INTO `lc_gomoku_game` VALUES (3, 29, 30, 29, 30, 2, '111110000000000222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 1, 1, 4, 0, '2026-11-12 14:44:21', '2026-11-12 14:44:21');

-- ----------------------------
-- Table structure for lc_login_log
-- ----------------------------
DROP TABLE IF EXISTS `lc_login_log`;
CREATE TABLE `lc_login_log`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` bigint UNSIGNED NULL DEFAULT NULL COMMENT '登录用户id（登录失败且账号不存在时为 NULL）',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '登录时使用的账号名（成功/失败都记录，便于审计）',
  `login_type` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'password' COMMENT '登录方式：password-账号密码',
  `ip` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '登录来源 IP（已处理 X-Forwarded-For）',
  `user_agent` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '客户端 User-Agent',
  `success` tinyint NOT NULL DEFAULT 1 COMMENT '是否成功：1-成功，0-失败',
  `fail_reason` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '失败原因：账号不存在/已禁用、密码错误、参数缺失',
  `login_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '登录发生时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '记录创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_lc_login_log_user`(`user_id` ASC) USING BTREE,
  INDEX `idx_lc_login_log_success`(`success` ASC) USING BTREE,
  INDEX `idx_lc_login_log_time`(`login_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-登录日志表（每次登录追加一条，永不覆盖）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of lc_login_log
-- ----------------------------
INSERT INTO `lc_login_log` VALUES (1, 30, 'upload_test_02', 'password', '0:0:0:0:0:0:0:1', 'curl/8.0.1', 1, NULL, '2026-11-12 14:39:14', '2026-11-12 14:39:14');
INSERT INTO `lc_login_log` VALUES (2, 4, 'cc', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-12 14:41:38', '2026-11-12 14:41:38');
INSERT INTO `lc_login_log` VALUES (3, 2, 'xx', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-12 14:41:57', '2026-11-12 14:41:57');
INSERT INTO `lc_login_log` VALUES (4, 29, 'upload_test_01', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-12 15:05:47', '2026-11-12 15:05:47');

-- ----------------------------
-- Table structure for lc_refresh_token
-- ----------------------------
DROP TABLE IF EXISTS `lc_refresh_token`;
CREATE TABLE `lc_refresh_token`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `user_id` bigint UNSIGNED NOT NULL COMMENT '所属用户 id',
  `token_hash` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '刷新令牌的 SHA-256 摘要（原始令牌只存前端，库里不落明文）',
  `family_id` varchar(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '令牌族：同族令牌成链轮换，整族作废时一次性吊销',
  `expires_at` datetime NOT NULL COMMENT '过期时间',
  `revoked` tinyint NOT NULL DEFAULT 0 COMMENT '吊销状态：0-有效，1-已轮换（正常），2-已吊销（登出/重放）',
  `revoked_reason` varchar(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '吊销原因：rotate-正常轮换 / logout-主动登出 / replay-重放检测 / expired-过期清理',
  `replaced_by` char(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '轮换后接替它的令牌摘要，可沿链追溯整条会话',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_lc_refresh_token_hash`(`token_hash` ASC) USING BTREE,
  INDEX `idx_lc_refresh_token_user`(`user_id` ASC) USING BTREE,
  INDEX `idx_lc_refresh_token_family`(`family_id` ASC) USING BTREE,
  INDEX `idx_lc_refresh_token_expire`(`expires_at` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-刷新令牌表（双令牌方案）' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of lc_refresh_token
-- ----------------------------
INSERT INTO `lc_refresh_token` VALUES (1, 29, '4c9ca8d62d9807c421a0f0cf6bc72f4d316316d8dd77f9e586e2b3c0c15c7fa4', 'f881baf6-a1ef-4e64-b2a9-876b21eff820', '2026-11-27 15:05:47', 0, NULL, NULL, '2026-11-12 15:05:47', '2026-11-12 15:05:47');

-- ----------------------------
-- Table structure for lc_sms_code
-- ----------------------------
DROP TABLE IF EXISTS `lc_sms_code`;
CREATE TABLE `lc_sms_code`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '手机号',
  `code` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '验证码',
  `scene` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'register' COMMENT '验证码场景：register-注册，reset_password-重置密码',
  `expire_time` datetime NOT NULL COMMENT '过期时间',
  `consumed` tinyint NOT NULL DEFAULT 0 COMMENT '是否已使用：0-未使用，1-已使用',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_lc_sms_code_phone_scene`(`phone` ASC, `scene` ASC, `create_time` ASC) USING BTREE,
  INDEX `idx_lc_sms_code_expire_time`(`expire_time` ASC) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-短信验证码表' ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of lc_sms_code
-- ----------------------------

-- ----------------------------
-- Table structure for lc_user
-- ----------------------------
DROP TABLE IF EXISTS `lc_user`;
CREATE TABLE `lc_user`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户名（唯一）',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '手机号（选填，非空时唯一）',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '密码（BCrypt 哈希，不存明文）',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '昵称，默认与用户名一致',
  `avatar` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '头像地址（用户上传后的相对路径；空则用首字母默认头像）',
  `role` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'user' COMMENT '角色：user-普通用户，admin-管理员',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '账号状态：1-正常，0-禁用',
  `pwd_version` int NOT NULL DEFAULT 1 COMMENT '密码版本号：改密码时 +1，用于让所有旧 token 立即失效',
  `last_login_time` datetime NULL DEFAULT NULL COMMENT '最近一次登录时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `permission` tinyint NOT NULL DEFAULT 1 COMMENT '权限：1-默认权限（普通用户），0-管理员权限（可进入后台管理系统）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_lc_user_username`(`username` ASC) USING BTREE,
  UNIQUE INDEX `uk_lc_user_phone`(`phone` ASC) USING BTREE,
  INDEX `idx_lc_user_create_time`(`create_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 31 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_user
-- ----------------------------
INSERT INTO `lc_user` VALUES (1, 'tester01', NULL, '$2a$10$BCOIjfKAsurIU1kEh1JSwOF3TTzrD25CnqhwGQ1xZpHwfB0F6IpeW', 'tester01', NULL, 'user', 1, 1, '2026-10-09 14:33:30', '2026-10-09 14:33:27', '2026-10-09 14:33:29', 1);
INSERT INTO `lc_user` VALUES (2, 'xx', NULL, '$2a$10$KRZ29HhOy1NxsamV46KRL.wlYwTILagT0qUnPCk2w3IIR0qE0N/he', 'xx', NULL, 'admin', 1, 1, '2026-11-12 14:41:57', '2026-10-28 16:25:05', '2026-11-12 14:41:57', 0);
INSERT INTO `lc_user` VALUES (3, 'admin', NULL, '$2a$10$fZZ0GOgwjyUpD4bGVPhS8OZHaZp6DdRHMy9EeB8KGgXlrTjhuWP0i', '超级管理员', NULL, 'admin', 1, 1, '2026-11-12 13:57:29', '2026-10-28 16:56:11', '2026-11-12 13:57:29', 0);
INSERT INTO `lc_user` VALUES (4, 'cc', NULL, '$2a$10$8iFeImcuRP32nl23AHR64OKxUcJ.mQzz2LvvzjvDKWjarLm.Dg1bu', 'cc', NULL, 'user', 1, 1, '2026-11-12 14:41:38', '2026-10-28 23:10:05', '2026-11-12 14:41:37', 1);
INSERT INTO `lc_user` VALUES (29, 'upload_test_01', NULL, '$2a$10$JlBIqQwV7nILWT6H.RqA5O6LsOxX8THSbfj6U03KEjm8mEY5IVOCS', 'upload_test_01', '/uploads/avatars/a1a72b556a4449e680964674717a3dc5.png', 'user', 1, 1, '2026-11-12 15:05:47', '2026-11-12 13:54:48', '2026-11-12 15:05:47', 1);
INSERT INTO `lc_user` VALUES (30, 'upload_test_02', NULL, '$2a$10$u.OZ4wuThurQig1JetAtEumRlNEH065seGePQuIyjamsjvDtj3glW', 'upload_test_02', NULL, 'user', 1, 1, '2026-11-12 14:39:14', '2026-11-12 14:39:01', '2026-11-12 14:39:14', 1);

SET FOREIGN_KEY_CHECKS = 1;
