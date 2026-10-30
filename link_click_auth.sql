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

 Date: 30/10/2026 14:53:26
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
  `visibility` tinyint NOT NULL DEFAULT 0 COMMENT '可见性：0-仅自己，1-公开到档案墙',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_lc_archive_user`(`user_id` ASC) USING BTREE,
  INDEX `idx_lc_archive_public`(`visibility` ASC, `update_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 13 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-时光档案表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_archive
-- ----------------------------
INSERT INTO `lc_archive` VALUES (1, 1, '雨中私语', '那是 2019 年的春天，一场突如其来的雨把我们困在便利店屋檐下。你递来半杯热可可，雨声里我们谁都没有多说话，却记了很久。', '2019-04-12', '私语', 1, '2026-10-09 15:00:00', '2026-10-09 15:00:00');
INSERT INTO `lc_archive` VALUES (2, 1, '未寄出的信', '写给三年前的你：有些话当时没敢说出口，后来发现，不说也挺好。这封信就留在抽屉里，当作一段没说完的时光。', '2021-07-08', '信件', 1, '2026-10-09 15:05:00', '2026-10-09 15:05:00');
INSERT INTO `lc_archive` VALUES (3, 1, '天台上的告白', '跨年钟声倒数到三的时候，你突然说喜欢我。烟火在头顶炸开，我愣了三秒才回过神来。', '2019-12-24', '告白', 1, '2026-10-09 15:10:00', '2026-10-09 15:10:00');
INSERT INTO `lc_archive` VALUES (4, 1, '跨年烟火下的约定', '我们说好每一年跨年都要在同一个地方见面，看同一场烟火。今年是你缺席的第一年。', '2020-12-31', '约定', 1, '2026-10-09 15:15:00', '2026-10-09 15:15:00');
INSERT INTO `lc_archive` VALUES (5, 1, '旧巷口的猫', '巷口那只橘猫又生了三宝，路过时它还是会蹭我的裤脚。有些陪伴不需要名字，也不需要结局。', '2022-03-15', '私语', 0, '2026-10-09 15:20:00', '2026-10-09 15:20:00');
INSERT INTO `lc_archive` VALUES (6, 1, '雨夜便利店', '加班到凌晨，便利店的关东煮和那首老歌，是这座城市留给独行人的温柔。', '2023-06-02', '私语', 0, '2026-10-09 15:25:00', '2026-10-09 15:25:00');
INSERT INTO `lc_archive` VALUES (7, 4, '雨中私语', NULL, '2026-10-30', '私语', 1, '2026-10-30 14:00:27', '2026-10-30 14:00:27');
INSERT INTO `lc_archive` VALUES (8, 4, '未寄出的信', NULL, '2026-10-30', '私语', 1, '2026-10-30 14:00:38', '2026-10-30 14:00:38');
INSERT INTO `lc_archive` VALUES (9, 4, '天台上的告白', NULL, '2026-10-30', '私语', 0, '2026-10-30 14:00:47', '2026-10-30 14:00:47');
INSERT INTO `lc_archive` VALUES (10, 4, '跨年烟火下的约定', NULL, '2026-10-30', '私语', 1, '2026-10-30 14:00:56', '2026-10-30 14:00:56');
INSERT INTO `lc_archive` VALUES (11, 4, '旧巷口的猫', NULL, '2026-10-30', '告白', 0, '2026-10-30 14:01:04', '2026-10-30 14:01:04');
INSERT INTO `lc_archive` VALUES (12, 4, '雨夜便利店', NULL, '2026-10-30', '信件', 1, '2026-10-30 14:01:13', '2026-10-30 14:01:13');

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
) ENGINE = InnoDB AUTO_INCREMENT = 10 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-刷新令牌表（双令牌方案）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_refresh_token
-- ----------------------------
INSERT INTO `lc_refresh_token` VALUES (1, 1, '30b08dc7a59945cf6c19214a1fd21fb7127e5e1255702a68776616f88a9efa09', '1befb004-f3e4-4205-a981-17df97f604d7', '2026-10-24 14:33:30', 0, NULL, NULL, '2026-10-09 14:33:29', '2026-10-09 14:33:29');
INSERT INTO `lc_refresh_token` VALUES (2, 3, 'f68a9b54027f637322433021b7206a45b452e6cd02fd69ac5c886c4306ed90b5', '5e1029df-d6a0-4dfa-b708-7bf9ca5d37de', '2026-11-14 13:58:23', 2, 'logout', NULL, '2026-10-30 13:58:22', '2026-10-30 13:58:44');
INSERT INTO `lc_refresh_token` VALUES (3, 3, '5d80a59bbfb469a84b922dc1cd6ad24b7668a1a2d91a84f6864dfd48df3ed9d2', 'bfffe943-9f4a-46c1-8f3a-23b2e5836b23', '2026-11-14 13:58:38', 2, 'logout', NULL, '2026-10-30 13:58:37', '2026-10-30 13:58:44');
INSERT INTO `lc_refresh_token` VALUES (4, 1, '41ac48a871ab3b274b61fd94980844ee36f1342a54b5c768168393242b22b2cc', '35800a84-d29f-4d2a-8dc6-8fc0ae737f22', '2026-11-14 13:58:55', 0, NULL, NULL, '2026-10-30 13:58:54', '2026-10-30 13:58:54');
INSERT INTO `lc_refresh_token` VALUES (5, 3, 'cc1fdc957288ecd8337071227a4eee4b63782eebe931573cc1ae9a52103636e1', '1beafd6c-f1ce-4019-9a6a-0730dd3f077d', '2026-11-14 13:59:20', 2, 'logout', NULL, '2026-10-30 13:59:20', '2026-10-30 13:59:46');
INSERT INTO `lc_refresh_token` VALUES (6, 4, '85dcdfedcdde3aaef7370e870523e64a5b00fdb65ff82f4cbac31994d30449ca', 'd7a35485-2d88-4ba9-830b-f1a39e01055f', '2026-11-14 14:00:08', 2, 'logout', NULL, '2026-10-30 14:00:07', '2026-10-30 14:43:34');
INSERT INTO `lc_refresh_token` VALUES (7, 3, '39df534a8f13c52de6bb133f770ec71b3ecfadd2be8ea829a0a7fbfc6a4c0974', 'a1040bec-0720-4725-b830-cd89d8a02701', '2026-11-14 14:43:43', 2, 'logout', NULL, '2026-10-30 14:43:42', '2026-10-30 14:47:59');
INSERT INTO `lc_refresh_token` VALUES (8, 4, '6c6105eea87f1a0c810f1218ac4da5d02af1223489ca951f7feabf76b854fa2b', '965abd87-c20e-4dc6-8936-31e3362aa58a', '2026-11-14 14:48:06', 2, 'logout', NULL, '2026-10-30 14:48:06', '2026-10-30 14:48:09');
INSERT INTO `lc_refresh_token` VALUES (9, 4, '0d555b1a5e6b04d612db7336dd0c3e5d596468b089748a8f4ee10359bec34f0e', 'bb4a8073-6372-4a83-967c-60e8b7923b3f', '2026-11-14 14:48:24', 0, NULL, NULL, '2026-10-30 14:48:24', '2026-10-30 14:48:24');

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
) ENGINE = InnoDB AUTO_INCREMENT = 2 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-短信验证码表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_sms_code
-- ----------------------------
INSERT INTO `lc_sms_code` VALUES (1, '13800138000', '918101', 'register', '2026-10-09 14:19:36', 0, '2026-10-09 14:14:36');

-- ----------------------------
-- Table structure for lc_user
-- ----------------------------
DROP TABLE IF EXISTS `lc_user`;
CREATE TABLE `lc_user`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '主键id',
  `username` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '用户名（唯一）',
  `phone` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '手机号（选填，非空时唯一）',
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '密码（明文存储，按需求不加密）',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '昵称，默认与用户名一致',
  `role` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'user' COMMENT '角色：user-普通用户，admin-管理员',
  `status` tinyint NOT NULL DEFAULT 1 COMMENT '账号状态：1-正常，0-禁用',
  `pwd_version` int NOT NULL DEFAULT 1 COMMENT '密码版本号：改密码时 +1，用于让所有旧 token 立即失效',
  `last_login_time` datetime NULL DEFAULT NULL COMMENT '最近一次登录时间',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  `permission` tinyint NOT NULL DEFAULT 1 COMMENT '权限：1-默认权限（普通用户，不可进入后台管理系统）/ 0-管理员权限（可看到后台管理入口并登录后台）',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE INDEX `uk_lc_user_username`(`username` ASC) USING BTREE,
  UNIQUE INDEX `uk_lc_user_phone`(`phone` ASC) USING BTREE,
  INDEX `idx_lc_user_create_time`(`create_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_user
-- ----------------------------
INSERT INTO `lc_user` VALUES (1, 'tester01', NULL, '123456', 'tester01', 'user', 1, 1, '2026-10-30 13:58:55', '2026-10-09 14:33:27', '2026-10-30 13:58:54', 1);
INSERT INTO `lc_user` VALUES (3, 'admin', NULL, 'admin123', '超级管理员', 'admin', 1, 1, '2026-10-30 14:43:43', '2026-10-28 00:00:00', '2026-10-30 14:43:42', 0);
INSERT INTO `lc_user` VALUES (4, 'xx', NULL, '123456', 'xx', 'admin', 1, 1, '2026-10-30 14:48:24', '2026-10-30 14:00:01', '2026-10-30 14:48:24', 0);

SET FOREIGN_KEY_CHECKS = 1;
