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

 Date: 06/11/2026 15:09:36
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
) ENGINE = InnoDB AUTO_INCREMENT = 10002 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-时光档案表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 61 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-刷新令牌表（双令牌方案）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_refresh_token
-- ----------------------------
INSERT INTO `lc_refresh_token` VALUES (1, 1, '30b08dc7a59945cf6c19214a1fd21fb7127e5e1255702a68776616f88a9efa09', '1befb004-f3e4-4205-a981-17df97f604d7', '2026-10-24 14:33:30', 0, NULL, NULL, '2026-10-09 14:33:29', '2026-10-09 14:33:29');
INSERT INTO `lc_refresh_token` VALUES (2, 2, '14d31c5574d9ebc4107bf7e60f73647c08963d2410d484e1412e1f536b441504', '11075034-e1a4-45cd-b62c-ea4cc5cbe3d8', '2026-11-12 16:25:09', 2, 'logout', NULL, '2026-10-28 16:25:09', '2026-10-28 23:09:46');
INSERT INTO `lc_refresh_token` VALUES (3, 2, '934619a7c0398255cba8740468161e7bbe3fac61f826a6ebb849d130d34e9b1e', '50f6279e-3964-4436-aa87-bc2b9d01ae26', '2026-11-12 23:08:29', 2, 'logout', NULL, '2026-10-28 23:08:29', '2026-10-28 23:09:46');
INSERT INTO `lc_refresh_token` VALUES (4, 4, 'c0abd166501b292657d91ccd1c96ff053dea41a4530b229c5a7044dc32982046', '8594e333-7a6f-4835-8fb2-7271c6ebebac', '2026-11-12 23:10:15', 2, 'logout', NULL, '2026-10-28 23:10:15', '2026-10-28 23:11:00');
INSERT INTO `lc_refresh_token` VALUES (5, 2, '27a96540e0fd9d4d6eacd2f42cb022b2e8c3cd16276d68aa52394b7bb0e495f8', 'd0c48e96-bcff-4d1d-a191-1e91c7ecf877', '2026-11-12 23:11:02', 2, 'logout', NULL, '2026-10-28 23:11:02', '2026-10-29 00:08:51');
INSERT INTO `lc_refresh_token` VALUES (6, 2, '1453f66f445c309f2dd55b36cdb99bec9ec0106085d9e680ec00bf83a5731eb5', '2d16a9d4-356d-431f-9797-7efbcc8e9dd6', '2026-11-12 23:16:18', 2, 'logout', NULL, '2026-10-28 23:16:17', '2026-10-29 00:08:51');
INSERT INTO `lc_refresh_token` VALUES (7, 2, '0de25930400e9a1ae88676e35e5cf4e4b0ac37234b62dffbfd382cfd411816c4', '2e87f342-1396-44af-8e65-ae003f471640', '2026-11-12 23:21:38', 2, 'logout', NULL, '2026-10-28 23:21:38', '2026-10-29 00:08:51');
INSERT INTO `lc_refresh_token` VALUES (8, 2, '99176ee7ad9d91b71460da426ab00050172616ad9d80c678d7620dc1b7c099cf', 'e7ddbdcc-39e1-4854-b299-eee5823e323c', '2026-11-12 23:24:09', 2, 'logout', NULL, '2026-10-28 23:24:08', '2026-10-29 00:08:51');
INSERT INTO `lc_refresh_token` VALUES (9, 2, '64113e8d87562cde77ad1cb33e268e9859c51395b01c38752937fe2caaf9d7da', 'ada817b7-a666-4fa3-9f52-cc765aeb4795', '2026-11-12 23:24:09', 2, 'logout', NULL, '2026-10-28 23:24:09', '2026-10-29 00:08:51');
INSERT INTO `lc_refresh_token` VALUES (10, 3, '095d6f430aa0c69263fc8973ea9bcad6e932c7f485dfad0e74da4080859d20f7', '0694d799-a9ce-4907-9d4e-92ffd241fed4', '2026-11-12 23:35:28', 2, 'logout', NULL, '2026-10-28 23:35:27', '2026-11-05 18:44:11');
INSERT INTO `lc_refresh_token` VALUES (11, 3, 'f1ff77ee3c0f2698e0c407346710a3fc756ce0a5bcf27edbfca24d87ab7cc311', '3a450e6e-c73c-4ecb-94f0-e8744c00bb20', '2026-11-13 00:05:39', 2, 'logout', NULL, '2026-10-29 00:05:39', '2026-11-05 18:44:11');
INSERT INTO `lc_refresh_token` VALUES (12, 3, '8e0490e3436a5d8c89e6f5681eecd98c9aa0340cf75ca2a1de63b0f41c1d07ab', '59f90166-aa58-41af-9fe2-a7ed2a0536db', '2026-11-13 00:06:53', 2, 'logout', NULL, '2026-10-29 00:06:53', '2026-11-05 18:44:11');
INSERT INTO `lc_refresh_token` VALUES (13, 3, '5574bc449e7f82936bf241630dafc5fd3c18f5a3c58c42205b2d3a0dabfdd815', '4589aebd-1278-4fd9-aab2-8d750535d783', '2026-11-13 00:08:17', 2, 'logout', NULL, '2026-10-29 00:08:16', '2026-11-05 18:44:11');
INSERT INTO `lc_refresh_token` VALUES (14, 2, '74febb31e8b00614deb4e90f7cff3a5404e7b94aa3555aafcb3b28093f18a25d', '78e765cf-186a-4e86-9b24-2569d974878c', '2026-11-13 00:08:24', 2, 'logout', NULL, '2026-10-29 00:08:24', '2026-10-29 00:08:51');
INSERT INTO `lc_refresh_token` VALUES (15, 2, '5ad893c46919639a86111f26b48ae4ef12b4b223b7217125c600cd0877a61bf3', '88769479-13d8-4b42-9d8b-cbea9647bb0c', '2026-11-13 00:08:29', 2, 'logout', NULL, '2026-10-29 00:08:29', '2026-10-29 00:08:51');
INSERT INTO `lc_refresh_token` VALUES (16, 3, '3cc75ba4476c21d19b114deca2ed682a9503a8a9ab0db75a4b9f8c1695e12070', '97abf14f-ab3e-4c58-b96f-001b995df552', '2026-11-13 00:09:19', 2, 'logout', NULL, '2026-10-29 00:09:18', '2026-11-05 18:44:11');
INSERT INTO `lc_refresh_token` VALUES (17, 2, '0fc0e511dbcc9cd9affd2444030b502ce8f7711b26c0af099d62c6a21f1fb8e6', '7809777b-b580-4f7e-83a6-7547b7fb8c2d', '2026-11-13 00:09:46', 2, 'logout', NULL, '2026-10-29 00:09:46', '2026-11-05 18:43:45');
INSERT INTO `lc_refresh_token` VALUES (18, 3, '856687aa23603c01bc90074a9d2629961d42d1bd67caf3e03db67a73823766d7', 'c248006a-d2b8-437d-ac81-1d9033f6a231', '2026-11-13 00:13:06', 2, 'logout', NULL, '2026-10-29 00:13:05', '2026-11-05 18:44:11');
INSERT INTO `lc_refresh_token` VALUES (19, 2, '9d40b259dc8c30586891c3f86e42f6076841951663fb6c146c6eac1fcf7250a6', '8ade5f06-fa0f-441e-b10e-9710566bb002', '2026-11-13 00:32:10', 2, 'logout', NULL, '2026-10-29 00:32:10', '2026-11-05 18:43:45');
INSERT INTO `lc_refresh_token` VALUES (20, 2, '1ac1e02179b0cee1355c25e6196cd02a5e286075c3ace10df574c7e1a7997d38', '8881bf7d-04aa-48c0-8bb8-ad53750840db', '2026-11-20 18:35:36', 2, 'logout', NULL, '2026-11-05 18:35:35', '2026-11-05 18:43:45');
INSERT INTO `lc_refresh_token` VALUES (21, 2, 'd7ea3c1a35e691900f2ffe3560ac6244764f3b502d1c16ff88c1ac8489754c5a', 'd2874a76-aff9-4171-b676-de0b40589bac', '2026-11-20 18:43:50', 2, 'logout', NULL, '2026-11-05 18:43:50', '2026-11-05 18:43:52');
INSERT INTO `lc_refresh_token` VALUES (22, 3, '2e202d3526f19332c5f97cf007c6ad7da555a7722f33ee03d42e2075fac8b8b2', '9a26f3cf-5198-4d7d-beb2-f879d2955d5e', '2026-11-20 18:44:04', 2, 'logout', NULL, '2026-11-05 18:44:03', '2026-11-05 18:44:11');
INSERT INTO `lc_refresh_token` VALUES (23, 2, '3a5dcac5f01d534b05a2b05e85a253be432150e995e3ac5158bd291a20135d20', 'fdf59fd6-8225-435d-a19e-275d4ae41ee7', '2026-11-20 18:45:00', 2, 'logout', NULL, '2026-11-05 18:45:00', '2026-11-05 18:54:52');
INSERT INTO `lc_refresh_token` VALUES (24, 3, '8c8bb9d127f3a7f3afe8f304d353fdfa9ef287b25b20c1c6e2880d09abb17d58', '70561c00-c9f0-4943-9de2-d0b18923d7cf', '2026-11-20 18:55:02', 2, 'logout', NULL, '2026-11-05 18:55:01', '2026-11-06 14:03:24');
INSERT INTO `lc_refresh_token` VALUES (25, 5, '3983ccb5329c163b04c484e08610ebc94380469f4159c37b008bbca2ea3a49e0', 'c27b2209-4d4b-425f-82e5-87aaf226e4ad', '2026-11-20 21:17:10', 0, NULL, NULL, '2026-11-05 21:17:09', '2026-11-05 21:17:09');
INSERT INTO `lc_refresh_token` VALUES (26, 5, '4b8da0efcfc1e0c0e6266b55549ee38e56ebf83937c5f31c248071ecbb773df9', '376b1a84-aa09-427e-9b0b-7c12fe1a6d58', '2026-11-20 21:23:30', 0, NULL, NULL, '2026-11-05 21:23:29', '2026-11-05 21:23:29');
INSERT INTO `lc_refresh_token` VALUES (27, 6, '83de55036bfc1d07bb6e14f0e3e5bcce87724283e36283fb9056935542ef7317', 'f2541d2b-cfa6-46a8-afd3-f29471616e78', '2026-11-20 21:25:36', 0, NULL, NULL, '2026-11-05 21:25:35', '2026-11-05 21:25:35');
INSERT INTO `lc_refresh_token` VALUES (28, 7, '63d447ed427ba4ede9b7ac532e1d57ecab7555cae16837b901db43b18f3ec8ac', '4fc6b9fa-38c9-42e6-8265-952f64267676', '2026-11-20 21:28:11', 0, NULL, NULL, '2026-11-05 21:28:11', '2026-11-05 21:28:11');
INSERT INTO `lc_refresh_token` VALUES (29, 8, '2d0d86a863b0a8f996414f8b6cd33a07eafaf930ec3c2772f8a0f5459f1f762c', '2d4bbadd-9a24-47c4-b61a-2c30a04dbca2', '2026-11-20 21:30:25', 0, NULL, NULL, '2026-11-05 21:30:25', '2026-11-05 21:30:25');
INSERT INTO `lc_refresh_token` VALUES (30, 9, '267714f56c7f5ce24c930072acd18d70693137574c663563ce41e0126264962e', '4adbc8c1-9e3f-4ed1-8dc5-5396bfb0c8ee', '2026-11-20 21:33:06', 0, NULL, NULL, '2026-11-05 21:33:06', '2026-11-05 21:33:06');
INSERT INTO `lc_refresh_token` VALUES (31, 10, 'f50d8cc6b3dfc9e59d999b2114fc60420209bbf5967546c24f0888272e381e96', '8cc78cf1-b3f3-4f6b-820a-27c1ea34560d', '2026-11-20 21:33:48', 0, NULL, NULL, '2026-11-05 21:33:48', '2026-11-05 21:33:48');
INSERT INTO `lc_refresh_token` VALUES (32, 11, '1296b61cdd2d8f9d7172d0a77a7e4e2abe088e48d828f2cd8dd6e314331c49ff', 'cc0856f2-a661-4322-a406-4b63ea733e35', '2026-11-20 21:35:07', 0, NULL, NULL, '2026-11-05 21:35:07', '2026-11-05 21:35:07');
INSERT INTO `lc_refresh_token` VALUES (33, 12, 'b381d0bb586994f1ea67292fbdd4ade756a23efa18a2f111379d7525df581f82', 'a056ec17-e27c-4597-b5b0-8da4ded38652', '2026-11-20 21:55:04', 0, NULL, NULL, '2026-11-05 21:55:04', '2026-11-05 21:55:04');
INSERT INTO `lc_refresh_token` VALUES (34, 13, 'e32d69986aa2841364070cd9bd62082c6b25c2c1b8f5565140bdc4b433dca25b', '0478ca02-218a-4e6b-8752-0b5227f32b61', '2026-11-20 21:57:55', 0, NULL, NULL, '2026-11-05 21:57:55', '2026-11-05 21:57:55');
INSERT INTO `lc_refresh_token` VALUES (35, 2, 'b0f1762c6a76210986e633070932afb072fa69377bc87a41b3f1b51b3b50291c', '74cee09a-ac50-4b6a-8bce-6ec889c1cb6e', '2026-11-20 21:58:46', 2, 'logout', NULL, '2026-11-05 21:58:46', '2026-11-05 22:15:46');
INSERT INTO `lc_refresh_token` VALUES (36, 14, 'cc37471486d5ecd8a315a35b69f6cb3a5e67fe3b51a36675f2725294dc814aca', 'e4275417-58ed-4bf1-aad4-f88a8f014f70', '2026-11-20 22:01:40', 0, NULL, NULL, '2026-11-05 22:01:40', '2026-11-05 22:01:40');
INSERT INTO `lc_refresh_token` VALUES (37, 15, '9f8764c8f675684c4339bfdb299e2040f8a465c87ba1c8d134c8591a548b6148', 'e879642a-1671-4d90-9bd4-0744ea2dc653', '2026-11-20 22:02:37', 0, NULL, NULL, '2026-11-05 22:02:37', '2026-11-05 22:02:37');
INSERT INTO `lc_refresh_token` VALUES (38, 16, 'e22867d5a185218796bce542118adc52a1c255f6db45815206854696dff9e4d9', '58c78ce1-f440-451c-9d72-f0d13b3e2e85', '2026-11-20 22:05:32', 0, NULL, NULL, '2026-11-05 22:05:31', '2026-11-05 22:05:31');
INSERT INTO `lc_refresh_token` VALUES (39, 17, 'cc90b437e52fea1c12b1c426d53220386e811fb3ce5abc544887724d5d6a7b58', '1a35a447-4e88-4bd8-add2-e307f8b384be', '2026-11-20 22:06:25', 0, NULL, NULL, '2026-11-05 22:06:24', '2026-11-05 22:06:24');
INSERT INTO `lc_refresh_token` VALUES (40, 18, 'f82b672edd714583408b0f5846c14ea433b675b0953c13f3d0457640ce779b14', 'a2cfeb07-71c6-4173-93d1-3d046659d247', '2026-11-20 22:08:31', 0, NULL, NULL, '2026-11-05 22:08:30', '2026-11-05 22:08:30');
INSERT INTO `lc_refresh_token` VALUES (41, 19, '5308858bfaa1131287b305fee28357ffbb9c71a1eec65615403dcf116a981489', 'f7bc4c27-0434-4ab8-9d8d-59055efc415b', '2026-11-20 22:10:49', 0, NULL, NULL, '2026-11-05 22:10:49', '2026-11-05 22:10:49');
INSERT INTO `lc_refresh_token` VALUES (42, 20, '3bf95ae73d40523a19e025b05a8a156638c668cfd9d1e6b6e70c90b1eee036cd', '88d61e96-17af-4425-93d7-307f328878f4', '2026-11-20 22:11:47', 0, NULL, NULL, '2026-11-05 22:11:46', '2026-11-05 22:11:46');
INSERT INTO `lc_refresh_token` VALUES (43, 21, 'c7c36a450aca1145c498a1b6a41cad7cbacd67b7586435c2679d4de1ac434952', '6ad7d916-c59b-4564-8ea4-678feff86393', '2026-11-20 22:12:34', 0, NULL, NULL, '2026-11-05 22:12:33', '2026-11-05 22:12:33');
INSERT INTO `lc_refresh_token` VALUES (44, 3, '063f33e5b53fe61121637ba71f44a08700eebd64a824c3d548f3c53f95ffddf3', '7ff5ebde-c254-47ed-9f2a-ef1662614f04', '2026-11-20 22:15:57', 2, 'logout', NULL, '2026-11-05 22:15:57', '2026-11-06 14:03:24');
INSERT INTO `lc_refresh_token` VALUES (45, 22, '60150c3202b6cf7cc46fe9e1c4b8744f55baa284b02de52ad7d77a79f2d9e70a', 'd60083ee-bb63-469c-b0bf-6cf2bbef9bf5', '2026-11-20 22:16:06', 0, NULL, NULL, '2026-11-05 22:16:05', '2026-11-05 22:16:05');
INSERT INTO `lc_refresh_token` VALUES (46, 23, 'ac91a30e63c46b1a5e5c1bbbe121268cf0f5845fa07eb0a8a47d327cd7b6cea8', 'b93ae7cd-77b8-4152-82a8-79cc8bd4e36d', '2026-11-20 22:17:26', 0, NULL, NULL, '2026-11-05 22:17:25', '2026-11-05 22:17:25');
INSERT INTO `lc_refresh_token` VALUES (47, 24, '3f933285e9fd09d939b203b44c54a1d5dc63d9ec5ce90524c733a564d44305f2', 'c547a08b-48ef-490b-8ebc-1a209f2c5556', '2026-11-20 22:18:17', 0, NULL, NULL, '2026-11-05 22:18:17', '2026-11-05 22:18:17');
INSERT INTO `lc_refresh_token` VALUES (48, 25, '2fe38e4892258e667f2ea52a3223b06804622eedba41d025ba7d849f6afe076a', '144b0a4f-6e39-425e-95de-1582c85c4fc3', '2026-11-20 22:19:54', 0, NULL, NULL, '2026-11-05 22:19:54', '2026-11-05 22:19:54');
INSERT INTO `lc_refresh_token` VALUES (49, 26, 'c68c8f2ff764167914e0e50193b2373c3e33434cb7eaa5cfce2d7dc3ea0c82e0', 'c6d4736f-64ba-454b-b640-f03de1226993', '2026-11-20 22:21:36', 0, NULL, NULL, '2026-11-05 22:21:36', '2026-11-05 22:21:36');
INSERT INTO `lc_refresh_token` VALUES (50, 27, '0e042063d6b75035e74dd21eb7d913118ba24e41cbc2483d2f4899745a42d618', '68e9b6b8-9d7c-4a4b-ad30-14e22bc74b36', '2026-11-20 22:21:50', 0, NULL, NULL, '2026-11-05 22:21:50', '2026-11-05 22:21:50');
INSERT INTO `lc_refresh_token` VALUES (51, 28, 'f253198b057e62ddbc0ab872c6b7c9a92fbd9906f88e0bbed52c1acb9718bc80', 'c6829ec8-4c02-4f02-9c43-ce94abe7bcf9', '2026-11-20 22:22:27', 0, NULL, NULL, '2026-11-05 22:22:26', '2026-11-05 22:22:26');
INSERT INTO `lc_refresh_token` VALUES (52, 3, '6a80202d9b6bb766d5331c7fdb3622861338389f3b589d82807a225898347b67', 'a137863e-b987-46be-8215-19b5b65210d6', '2026-11-20 22:37:12', 2, 'logout', NULL, '2026-11-05 22:37:11', '2026-11-06 14:03:24');
INSERT INTO `lc_refresh_token` VALUES (53, 3, '04f8a5e8fccd90dff07255f3cc5757d122b51fdb2342b85a6b19a1b71c82f7d1', 'a43d59b9-41d4-495a-af4e-83903b968a9e', '2026-11-20 22:37:23', 2, 'logout', NULL, '2026-11-05 22:37:22', '2026-11-06 14:03:24');
INSERT INTO `lc_refresh_token` VALUES (54, 2, '21c9e841da9de9d14bd70feedf224fb8a8855c27ff837a32587a4c34dae18f70', 'b3d737fa-5c9c-427e-a70b-61bc98d4610a', '2026-11-21 14:01:17', 2, 'logout', NULL, '2026-11-06 14:01:17', '2026-11-06 14:03:11');
INSERT INTO `lc_refresh_token` VALUES (55, 2, 'fac8d5bd8458eb554faef91e81dd1dff2f1d56a374d4a497129124978b887ffa', '1b1cd6ed-a27e-4324-b1f3-be1863d651c3', '2026-11-21 14:01:27', 2, 'logout', NULL, '2026-11-06 14:01:26', '2026-11-06 14:03:11');
INSERT INTO `lc_refresh_token` VALUES (56, 3, 'a29a3b3ec3bee144763ccc3c9246c53d1fa5a4dcfe90fce20d983b01ee1ebd4a', '9936ff2b-ad2e-498f-9c78-f32ff3ea2a3e', '2026-11-21 14:03:21', 2, 'logout', NULL, '2026-11-06 14:03:20', '2026-11-06 14:03:24');
INSERT INTO `lc_refresh_token` VALUES (57, 2, '7fbb5d7aaf5fa8a3f188f718e6fff9e9f1c16a454ac676033463a30fce526594', '8d8434bf-684e-49b3-8757-c047abf15a16', '2026-11-21 14:53:00', 0, NULL, NULL, '2026-11-06 14:53:00', '2026-11-06 14:53:00');
INSERT INTO `lc_refresh_token` VALUES (58, 2, '4278fe7ca41f21238cebdbf4646f4f4dc4c7b4bac509467b081d245fab90afd7', '9ac32672-c161-4af7-894c-c69ef1bd440d', '2026-11-21 15:04:57', 0, NULL, NULL, '2026-11-06 15:04:57', '2026-11-06 15:04:57');
INSERT INTO `lc_refresh_token` VALUES (59, 4, 'bd93da7164f4cee2e72d4ac10c1a38d5ceb35feb2661e1d0d375f31f77949dad', 'a76fcdd8-ee6c-4056-8c1e-e03d7bbbd389', '2026-11-21 15:04:57', 0, NULL, NULL, '2026-11-06 15:04:57', '2026-11-06 15:04:57');
INSERT INTO `lc_refresh_token` VALUES (60, 2, '35bad4c73efada839852a3e17d095bad76aba75fb65633a921936999881153bd', 'a1f366bc-2e64-4443-99a9-d764dadea9c4', '2026-11-21 15:05:31', 0, NULL, NULL, '2026-11-06 15:05:30', '2026-11-06 15:05:30');

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
  `password` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '密码（BCrypt 哈希，不存明文）',
  `nickname` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL COMMENT '昵称，默认与用户名一致',
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
) ENGINE = InnoDB AUTO_INCREMENT = 29 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_user
-- ----------------------------
INSERT INTO `lc_user` VALUES (1, 'tester01', NULL, '$2a$10$BCOIjfKAsurIU1kEh1JSwOF3TTzrD25CnqhwGQ1xZpHwfB0F6IpeW', 'tester01', 'user', 1, 1, '2026-10-09 14:33:30', '2026-10-09 14:33:27', '2026-10-09 14:33:29', 1);
INSERT INTO `lc_user` VALUES (2, 'xx', NULL, '$2a$10$KRZ29HhOy1NxsamV46KRL.wlYwTILagT0qUnPCk2w3IIR0qE0N/he', 'xx', 'admin', 1, 1, '2026-11-06 15:05:31', '2026-10-28 16:25:05', '2026-11-06 15:05:30', 0);
INSERT INTO `lc_user` VALUES (3, 'admin', NULL, '$2a$10$fZZ0GOgwjyUpD4bGVPhS8OZHaZp6DdRHMy9EeB8KGgXlrTjhuWP0i', '超级管理员', 'admin', 1, 1, '2026-11-06 14:03:21', '2026-10-28 16:56:11', '2026-11-06 14:03:20', 0);
INSERT INTO `lc_user` VALUES (4, 'cc', NULL, '$2a$10$8iFeImcuRP32nl23AHR64OKxUcJ.mQzz2LvvzjvDKWjarLm.Dg1bu', 'cc', 'user', 1, 1, '2026-11-06 15:04:57', '2026-10-28 23:10:05', '2026-11-06 15:04:57', 1);

SET FOREIGN_KEY_CHECKS = 1;
