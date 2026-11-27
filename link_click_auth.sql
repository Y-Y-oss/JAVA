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

 Date: 27/11/2026 15:12:43
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
) ENGINE = InnoDB AUTO_INCREMENT = 10009 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-时光档案表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_archive
-- ----------------------------
INSERT INTO `lc_archive` VALUES (1, 1, '雨中私语', '那是 2019 年的春天，一场突如其来的雨把我们困在便利店屋檐下。你递来半杯热可可，雨声里我们谁都没有多说话，却记了很久。', '2019-04-12', '私语', '/uploads/archives/b02f25d007434fc5ae0b7ddfd0a294fe.jpeg', 1, '2026-10-09 15:00:00', '2026-10-09 15:00:00');
INSERT INTO `lc_archive` VALUES (2, 1, '未寄出的信', '写给三年前的你：有些话当时没敢说出口，后来发现，不说也挺好。这封信就留在抽屉里，当作一段没说完的时光。', '2021-07-08', '信件', '/uploads/archives/779a245113ae4fd182c85150fcbd98c8.jpeg', 1, '2026-10-09 15:05:00', '2026-10-09 15:05:00');
INSERT INTO `lc_archive` VALUES (3, 1, '天台上的告白', '跨年钟声倒数到三的时候，你突然说喜欢我。烟火在头顶炸开，我愣了三秒才回过神来。', '2019-12-24', '告白', '/uploads/archives/71bce381e8dd4a74a4fdd9764e2bcc30.jpeg', 1, '2026-10-09 15:10:00', '2026-10-09 15:10:00');
INSERT INTO `lc_archive` VALUES (4, 1, '跨年烟火下的约定', '我们说好每一年跨年都要在同一个地方见面，看同一场烟火。今年是你缺席的第一年。', '2020-12-31', '约定', '/uploads/archives/e7eab0f6ad1e4c19bda416fea9df2ee4.png', 1, '2026-10-09 15:15:00', '2026-10-09 15:15:00');
INSERT INTO `lc_archive` VALUES (5, 1, '旧巷口的猫', '巷口那只橘猫又生了三宝，路过时它还是会蹭我的裤脚。有些陪伴不需要名字，也不需要结局。', '2022-03-15', '私语', '/uploads/archives/90603fa845bf4be49a5f91a9924f0779.jpg', 0, '2026-10-09 15:20:00', '2026-10-09 15:20:00');
INSERT INTO `lc_archive` VALUES (6, 1, '雨夜便利店', '加班到凌晨，便利店的关东煮和那首老歌，是这座城市留给独行人的温柔。', '2023-06-02', '私语', '/uploads/archives/c35fc90c3c514c4bb8514d596b3df3fd.jpg', 0, '2026-10-09 15:25:00', '2026-10-09 15:25:00');
INSERT INTO `lc_archive` VALUES (7, 2, '1', NULL, '2026-10-28', '私语', '/uploads/archives/da4f2d25235b45c28ba0582917a268be.jpeg', 1, '2026-10-28 16:25:20', '2026-10-28 16:25:20');
INSERT INTO `lc_archive` VALUES (8, 2, '未寄出的信', NULL, '2026-10-28', '私语', '/uploads/archives/6f098959021b420283750f46d13aab48.jpeg', 0, '2026-10-28 16:25:54', '2026-10-28 16:25:54');
INSERT INTO `lc_archive` VALUES (9, 2, '旧巷口的猫', NULL, '2026-10-28', '私语', '/uploads/archives/a10674faf8ec41e493d33c165092dd56.jpg', 0, '2026-10-28 16:39:15', '2026-10-28 16:39:15');
INSERT INTO `lc_archive` VALUES (10, 2, '雨夜便利店', NULL, '2026-10-28', '私语', '/uploads/archives/04cdf1061dbf4cda861d3f1b1df6c7ef.jpeg', 1, '2026-10-28 16:39:45', '2026-10-28 16:39:45');
INSERT INTO `lc_archive` VALUES (11, 2, '跨年烟火下的约定', NULL, '2026-10-28', '私语', '/uploads/archives/8ca1061996d342f8bac5f9df6cb097ec.jpeg', 0, '2026-10-28 16:40:04', '2026-10-28 16:40:04');
INSERT INTO `lc_archive` VALUES (12, 2, '雨中私语', NULL, '2026-10-28', '私语', '/uploads/archives/bc04deb55358477a8b933be9b5124179.jpeg', 0, '2026-10-28 16:41:09', '2026-10-28 16:41:09');
INSERT INTO `lc_archive` VALUES (13, 4, '1', NULL, '2026-10-28', '私语', '/uploads/archives/b8586b443c5b4b8fa2034396417f16a1.jpeg', 0, '2026-10-28 23:10:32', '2026-10-28 23:10:32');
INSERT INTO `lc_archive` VALUES (14, 4, '2', NULL, '2026-10-28', '私语', '/uploads/archives/ca4e0ae62aa94dcfa9f68715ce5bd3b6.jpeg', 1, '2026-10-28 23:10:44', '2026-10-28 23:10:44');
INSERT INTO `lc_archive` VALUES (10000, 2, 'a', NULL, '2026-11-06', '私语', '/uploads/archives/727a573f5754428ab729f42743b7a795.jpg', 0, '2026-11-06 14:04:07', '2026-11-06 14:04:07');
INSERT INTO `lc_archive` VALUES (10001, 2, 'b', NULL, '2026-11-06', '约定', '/uploads/archives/ce69000565ae4fbe9fdc0d23abdc0a61.jpg', 0, '2026-11-06 14:18:19', '2026-11-06 14:18:19');
INSERT INTO `lc_archive` VALUES (10002, 29, '上传测试档案', '验证照片上传与社区互动', NULL, NULL, '/uploads/archives/2949b4027ccd4d3ca1576c01e1df03ed.png', 1, '2026-11-12 14:13:30', '2026-11-12 14:13:30');
INSERT INTO `lc_archive` VALUES (10003, 2, '1', NULL, '2026-11-12', '告白', '/uploads/archives/d89e47bf8138479cbc1eac2d3cdd8c74.jpg', 1, '2026-11-12 14:15:18', '2026-11-12 14:15:18');
INSERT INTO `lc_archive` VALUES (10004, 1, '1', NULL, '2026-11-16', '私语', '/uploads/archives/d9e3217e20474638be3cab00e9910f29.jpg', 0, '2026-11-16 09:07:36', '2026-11-16 09:07:36');
INSERT INTO `lc_archive` VALUES (10005, 37, '好困', '早八好困', '2026-11-23', '私语', '/uploads/archives/159650ba5fd64d0b9156e77165009a33.png', 0, '2026-11-23 09:47:14', '2026-11-23 09:47:14');
INSERT INTO `lc_archive` VALUES (10006, 37, '美味主角团', NULL, '2026-11-26', '私语', '/uploads/archives/56744ad1ff1e40919d18b87351a5ee85.jpg', 1, '2026-11-26 14:11:45', '2026-11-26 14:11:45');
INSERT INTO `lc_archive` VALUES (10007, 37, '好看', NULL, '2026-11-26', '约定', '/uploads/archives/4dbb25a4e0e940ed973aa6b4f3157bd4.jpg', 1, '2026-11-26 14:19:15', '2026-11-26 14:19:15');
INSERT INTO `lc_archive` VALUES (10008, 37, '时光带刀人', NULL, '2026-11-26', '私语', '/uploads/archives/e47c130cc0ac46a0a941d36b8c81d1b3.png', 1, '2026-11-26 14:57:47', '2026-11-26 14:57:47');

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
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-档案评论表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-档案收藏表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 5 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-档案点赞表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_archive_like
-- ----------------------------
INSERT INTO `lc_archive_like` VALUES (2, 10002, 29, '2026-11-12 14:14:07');

-- ----------------------------
-- Table structure for lc_chat_message
-- ----------------------------
DROP TABLE IF EXISTS `lc_chat_message`;
CREATE TABLE `lc_chat_message`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '消息id',
  `sender_id` bigint UNSIGNED NOT NULL COMMENT '发送方用户id（lc_user.id）',
  `receiver_id` bigint UNSIGNED NOT NULL COMMENT '接收方用户id（lc_user.id）',
  `content` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '消息内容（≤1000字）',
  `read_flag` tinyint NOT NULL DEFAULT 0 COMMENT '已读状态：0-未读，1-已读（针对接收方）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_chat_pair`(`sender_id` ASC, `receiver_id` ASC, `create_time` ASC) USING BTREE,
  INDEX `idx_chat_receiver`(`receiver_id` ASC, `read_flag` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-好友私信表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_chat_message
-- ----------------------------
INSERT INTO `lc_chat_message` VALUES (1, 33, 34, '你好，我是 A', 1, '2026-11-16 09:14:19');
INSERT INTO `lc_chat_message` VALUES (2, 34, 33, '你好 A，我是 B', 1, '2026-11-16 09:14:19');
INSERT INTO `lc_chat_message` VALUES (3, 35, 36, '你好，我是 A', 1, '2026-11-16 09:14:37');
INSERT INTO `lc_chat_message` VALUES (4, 36, 35, '你好 A，我是 B', 1, '2026-11-16 09:14:37');
INSERT INTO `lc_chat_message` VALUES (5, 37, 2, 'qwwww', 1, '2026-11-26 13:57:52');
INSERT INTO `lc_chat_message` VALUES (6, 37, 2, 'qaq', 1, '2026-11-26 14:01:29');
INSERT INTO `lc_chat_message` VALUES (7, 37, 2, 'qaq', 1, '2026-11-26 14:36:11');
INSERT INTO `lc_chat_message` VALUES (8, 2, 37, '(｡•̀ᴗ-)✧', 1, '2026-11-26 14:59:11');
INSERT INTO `lc_chat_message` VALUES (9, 37, 2, '(￣▽￣\")', 1, '2026-11-26 14:59:19');
INSERT INTO `lc_chat_message` VALUES (10, 37, 2, '小白兔去面包店：\"有 100 个小面包吗？\" 老板说没有。第二天又问，还是没有。第三天老板特意备了 100 个，小白兔问：\"有 100 个小面包吗？\" 老板激动地说有！小白兔：\"那给我来两个。', 1, '2026-11-26 15:04:42');
INSERT INTO `lc_chat_message` VALUES (11, 37, 2, '(｡•̀ᴗ-)✧', 1, '2026-11-26 15:04:59');

-- ----------------------------
-- Table structure for lc_forum_post
-- ----------------------------
DROP TABLE IF EXISTS `lc_forum_post`;
CREATE TABLE `lc_forum_post`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '帖子id',
  `user_id` bigint UNSIGNED NOT NULL COMMENT '发帖用户id（lc_user.id）',
  `title` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '帖子标题（≤100字）',
  `content` text CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '帖子内容（≤3000字）',
  `reply_count` int NOT NULL DEFAULT 0 COMMENT '回复数（发回复时+1，删回复时-1）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发帖时间',
  `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_forum_post_user`(`user_id` ASC) USING BTREE,
  INDEX `idx_forum_post_time`(`create_time` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 4 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-论坛帖子表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_forum_post
-- ----------------------------
INSERT INTO `lc_forum_post` VALUES (3, 2, '1', 'o', 0, '2026-11-26 13:56:47', '2026-11-26 13:56:47');

-- ----------------------------
-- Table structure for lc_forum_reply
-- ----------------------------
DROP TABLE IF EXISTS `lc_forum_reply`;
CREATE TABLE `lc_forum_reply`  (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '回复id',
  `post_id` bigint UNSIGNED NOT NULL COMMENT '所属帖子id（lc_forum_post.id）',
  `user_id` bigint UNSIGNED NOT NULL COMMENT '回复用户id（lc_user.id）',
  `content` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT '回复内容（≤500字）',
  `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '回复时间',
  PRIMARY KEY (`id`) USING BTREE,
  INDEX `idx_reply_post`(`post_id` ASC, `create_time` ASC) USING BTREE,
  INDEX `idx_reply_user`(`user_id` ASC) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 3 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-论坛回复表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_forum_reply
-- ----------------------------

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
) ENGINE = InnoDB AUTO_INCREMENT = 12 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-好友关系表（同意后双向各一行）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_friend
-- ----------------------------
INSERT INTO `lc_friend` VALUES (1, 29, 30, 1, '2026-11-12 14:39:24', '2026-11-12 14:39:24');
INSERT INTO `lc_friend` VALUES (2, 30, 29, 1, '2026-11-12 14:39:25', '2026-11-12 14:39:25');
INSERT INTO `lc_friend` VALUES (3, 2, 4, 1, '2026-11-12 14:41:28', '2026-11-12 14:41:28');
INSERT INTO `lc_friend` VALUES (4, 4, 2, 1, '2026-11-12 14:41:46', '2026-11-12 14:41:46');
INSERT INTO `lc_friend` VALUES (5, 2, 1, 0, '2026-11-12 14:52:32', '2026-11-12 14:52:32');
INSERT INTO `lc_friend` VALUES (6, 33, 34, 1, '2026-11-16 09:14:19', '2026-11-16 09:14:19');
INSERT INTO `lc_friend` VALUES (7, 34, 33, 1, '2026-11-16 09:14:19', '2026-11-16 09:14:19');
INSERT INTO `lc_friend` VALUES (8, 35, 36, 1, '2026-11-16 09:14:37', '2026-11-16 09:14:37');
INSERT INTO `lc_friend` VALUES (9, 36, 35, 1, '2026-11-16 09:14:37', '2026-11-16 09:14:37');
INSERT INTO `lc_friend` VALUES (10, 37, 2, 1, '2026-11-23 09:33:31', '2026-11-23 09:33:31');
INSERT INTO `lc_friend` VALUES (11, 2, 37, 1, '2026-11-23 09:33:37', '2026-11-23 09:33:37');

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
) ENGINE = InnoDB AUTO_INCREMENT = 7 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-五子棋在线对局表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_gomoku_game
-- ----------------------------
INSERT INTO `lc_gomoku_game` VALUES (2, 29, 30, 29, 30, 2, '111110000000000222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 1, 2, 4, 1, '2026-11-12 14:42:09', '2026-11-12 14:42:09');
INSERT INTO `lc_gomoku_game` VALUES (3, 29, 30, 29, 30, 2, '111110000000000222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 1, 1, 4, 0, '2026-11-12 14:44:21', '2026-11-12 14:44:21');
INSERT INTO `lc_gomoku_game` VALUES (5, 37, 2, 37, 2, 2, '000000000000000000000000000000000000000000000000000000000000000000000000000000000010200100000000001012000000000112120000000000102221000000000022100000000000020000000000000000000000000000000000000000000000000000000000000000000', 2, 2, 7, 10, '2026-11-23 09:33:49', '2026-11-23 09:33:49');
INSERT INTO `lc_gomoku_game` VALUES (6, 2, 37, 2, 37, 2, '000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000021000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000', 2, 2, 8, 6, '2026-11-23 09:43:44', '2026-11-23 09:43:44');

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
) ENGINE = InnoDB AUTO_INCREMENT = 55 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-登录日志表（每次登录追加一条，永不覆盖）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_login_log
-- ----------------------------
INSERT INTO `lc_login_log` VALUES (1, 30, 'upload_test_02', 'password', '0:0:0:0:0:0:0:1', 'curl/8.0.1', 1, NULL, '2026-11-12 14:39:14', '2026-11-12 14:39:14');
INSERT INTO `lc_login_log` VALUES (2, 4, 'cc', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-12 14:41:38', '2026-11-12 14:41:38');
INSERT INTO `lc_login_log` VALUES (3, 2, 'xx', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-12 14:41:57', '2026-11-12 14:41:57');
INSERT INTO `lc_login_log` VALUES (4, 29, 'upload_test_01', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-12 15:05:47', '2026-11-12 15:05:47');
INSERT INTO `lc_login_log` VALUES (5, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 08:39:18', '2026-11-16 08:39:18');
INSERT INTO `lc_login_log` VALUES (6, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 08:53:54', '2026-11-16 08:53:54');
INSERT INTO `lc_login_log` VALUES (7, 2, 'xx', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 08:54:27', '2026-11-16 08:54:27');
INSERT INTO `lc_login_log` VALUES (8, NULL, 'test01', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 0, '账号不存在', '2026-11-16 08:59:34', '2026-11-16 08:59:34');
INSERT INTO `lc_login_log` VALUES (9, NULL, 'test1', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 0, '账号不存在', '2026-11-16 08:59:39', '2026-11-16 08:59:39');
INSERT INTO `lc_login_log` VALUES (10, 1, 'tester01', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 0, '密码错误', '2026-11-16 09:00:09', '2026-11-16 09:00:09');
INSERT INTO `lc_login_log` VALUES (11, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 0, '密码错误', '2026-11-16 09:00:39', '2026-11-16 09:00:39');
INSERT INTO `lc_login_log` VALUES (12, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:00:45', '2026-11-16 09:00:45');
INSERT INTO `lc_login_log` VALUES (13, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:00:59', '2026-11-16 09:00:59');
INSERT INTO `lc_login_log` VALUES (14, 4, 'cc', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:01:36', '2026-11-16 09:01:36');
INSERT INTO `lc_login_log` VALUES (15, 1, 'tester01', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:05:24', '2026-11-16 09:05:24');
INSERT INTO `lc_login_log` VALUES (16, 33, 'e2ea791658', 'password', '127.0.0.1', 'Python-urllib/3.13', 1, NULL, '2026-11-16 09:14:19', '2026-11-16 09:14:19');
INSERT INTO `lc_login_log` VALUES (17, 34, 'e2eb791658', 'password', '127.0.0.1', 'Python-urllib/3.13', 1, NULL, '2026-11-16 09:14:20', '2026-11-16 09:14:20');
INSERT INTO `lc_login_log` VALUES (18, 35, 'e2ea791676', 'password', '127.0.0.1', 'Python-urllib/3.13', 1, NULL, '2026-11-16 09:14:37', '2026-11-16 09:14:37');
INSERT INTO `lc_login_log` VALUES (19, 36, 'e2eb791676', 'password', '127.0.0.1', 'Python-urllib/3.13', 1, NULL, '2026-11-16 09:14:37', '2026-11-16 09:14:37');
INSERT INTO `lc_login_log` VALUES (20, 1, 'tester01', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:21:22', '2026-11-16 09:21:22');
INSERT INTO `lc_login_log` VALUES (21, 2, 'xx', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:21:43', '2026-11-16 09:21:43');
INSERT INTO `lc_login_log` VALUES (22, 29, 'upload_test_01', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 0, '密码错误', '2026-11-16 09:24:30', '2026-11-16 09:24:30');
INSERT INTO `lc_login_log` VALUES (23, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:24:50', '2026-11-16 09:24:50');
INSERT INTO `lc_login_log` VALUES (24, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 0, '密码错误', '2026-11-16 09:25:07', '2026-11-16 09:25:07');
INSERT INTO `lc_login_log` VALUES (25, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 0, '密码错误', '2026-11-16 09:25:13', '2026-11-16 09:25:13');
INSERT INTO `lc_login_log` VALUES (26, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:25:28', '2026-11-16 09:25:28');
INSERT INTO `lc_login_log` VALUES (27, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:26:29', '2026-11-16 09:26:29');
INSERT INTO `lc_login_log` VALUES (28, 2, 'xx', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:27:47', '2026-11-16 09:27:47');
INSERT INTO `lc_login_log` VALUES (29, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:36:19', '2026-11-16 09:36:19');
INSERT INTO `lc_login_log` VALUES (30, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:36:37', '2026-11-16 09:36:37');
INSERT INTO `lc_login_log` VALUES (31, 3, 'admin', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-16 09:48:56', '2026-11-16 09:48:56');
INSERT INTO `lc_login_log` VALUES (32, 2, 'xx', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-23 08:38:05', '2026-11-23 08:38:05');
INSERT INTO `lc_login_log` VALUES (33, 37, '55', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-23 08:39:56', '2026-11-23 08:39:56');
INSERT INTO `lc_login_log` VALUES (34, 2, 'xx', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-23 08:45:47', '2026-11-23 08:45:47');
INSERT INTO `lc_login_log` VALUES (35, 2, 'xx', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-23 09:26:59', '2026-11-23 09:26:59');
INSERT INTO `lc_login_log` VALUES (36, 37, '55', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-23 09:31:09', '2026-11-23 09:31:09');
INSERT INTO `lc_login_log` VALUES (37, 37, '55', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-23 09:44:01', '2026-11-23 09:44:01');
INSERT INTO `lc_login_log` VALUES (38, 2, 'xx', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-26 13:52:39', '2026-11-26 13:52:39');
INSERT INTO `lc_login_log` VALUES (39, 37, '55', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-26 13:56:09', '2026-11-26 13:56:09');
INSERT INTO `lc_login_log` VALUES (40, 2, 'xx', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-26 14:36:04', '2026-11-26 14:36:04');
INSERT INTO `lc_login_log` VALUES (41, 37, '55', 'password', '192.168.68.14', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-26 14:37:26', '2026-11-26 14:37:26');
INSERT INTO `lc_login_log` VALUES (42, 2, 'xx', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:00:33', '2026-11-27 14:00:33');
INSERT INTO `lc_login_log` VALUES (43, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:18:07', '2026-11-27 14:18:07');
INSERT INTO `lc_login_log` VALUES (44, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:18:40', '2026-11-27 14:18:40');
INSERT INTO `lc_login_log` VALUES (45, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:19:14', '2026-11-27 14:19:14');
INSERT INTO `lc_login_log` VALUES (46, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:20:14', '2026-11-27 14:20:14');
INSERT INTO `lc_login_log` VALUES (47, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:22:10', '2026-11-27 14:22:10');
INSERT INTO `lc_login_log` VALUES (48, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:28:37', '2026-11-27 14:28:37');
INSERT INTO `lc_login_log` VALUES (49, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:30:07', '2026-11-27 14:30:07');
INSERT INTO `lc_login_log` VALUES (50, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:31:15', '2026-11-27 14:31:15');
INSERT INTO `lc_login_log` VALUES (51, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:34:30', '2026-11-27 14:34:30');
INSERT INTO `lc_login_log` VALUES (52, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:36:24', '2026-11-27 14:36:24');
INSERT INTO `lc_login_log` VALUES (53, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:37:23', '2026-11-27 14:37:23');
INSERT INTO `lc_login_log` VALUES (54, 3, 'admin', 'password', '192.168.68.56', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/145.0.0.0 Safari/537.36', 1, NULL, '2026-11-27 14:38:31', '2026-11-27 14:38:31');

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
) ENGINE = InnoDB AUTO_INCREMENT = 45 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-刷新令牌表（双令牌方案）' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_refresh_token
-- ----------------------------
INSERT INTO `lc_refresh_token` VALUES (1, 29, '4c9ca8d62d9807c421a0f0cf6bc72f4d316316d8dd77f9e586e2b3c0c15c7fa4', 'f881baf6-a1ef-4e64-b2a9-876b21eff820', '2026-11-27 15:05:47', 0, NULL, NULL, '2026-11-12 15:05:47', '2026-11-12 15:05:47');
INSERT INTO `lc_refresh_token` VALUES (2, 3, '93d871c45a1318b104771aa0e9100f49f0f806d22f17ccd7d60f0302f3da0211', '05c259f3-ea35-4de2-bc16-b984da01108f', '2026-12-01 08:39:18', 2, 'logout', NULL, '2026-11-16 08:39:18', '2026-11-16 08:54:20');
INSERT INTO `lc_refresh_token` VALUES (3, 3, 'eed67586668cd5b4f8eea065f09e884b945286e83bd570a12525d8f53672ddc6', '9385ca71-1d81-4c8b-89c4-c4508cc39b09', '2026-12-01 08:53:54', 2, 'logout', NULL, '2026-11-16 08:53:54', '2026-11-16 08:54:20');
INSERT INTO `lc_refresh_token` VALUES (4, 2, '95378274855f771ae87c29e94c66bed1dd3a5e2aacdf5faddb5dad60a35064b8', '58f5a840-18d6-4091-aac1-d0fb1579b371', '2026-12-01 08:54:27', 2, 'logout', NULL, '2026-11-16 08:54:27', '2026-11-16 08:59:21');
INSERT INTO `lc_refresh_token` VALUES (5, 3, '5dff6fed8a14bb916c56e2c44680f33aa8abf50ce0a5b1d39394f54a1474fa03', '52802b33-c495-419a-a342-16ddb197a9d7', '2026-12-01 09:00:45', 2, 'logout', NULL, '2026-11-16 09:00:44', '2026-11-16 09:01:25');
INSERT INTO `lc_refresh_token` VALUES (6, 3, '0f1aa99618f6272e472849e9a6831ee7316cd82a8532f976c47add0573c39a80', '34dff5dc-c16a-4ee0-bf2c-c920cf1b7308', '2026-12-01 09:00:59', 2, 'logout', NULL, '2026-11-16 09:00:59', '2026-11-16 09:01:25');
INSERT INTO `lc_refresh_token` VALUES (7, 4, '8f7241687c803859f64c96eb713d35e37c3a3dca90a7c3adb1c9890dd62a4630', '54e39bd6-2205-4df4-8493-d1254dfac88f', '2026-12-01 09:01:36', 2, 'logout', NULL, '2026-11-16 09:01:36', '2026-11-16 09:05:06');
INSERT INTO `lc_refresh_token` VALUES (8, 1, '4c3b1c9a3f8cd97e0ef49159421be1d3ca82cc4e79fbdf91397c9170f6f30a20', '45d0bfa8-2d43-49b9-b156-8818872adcd1', '2026-12-01 09:05:24', 2, 'logout', NULL, '2026-11-16 09:05:24', '2026-11-16 09:20:54');
INSERT INTO `lc_refresh_token` VALUES (9, 33, '9fefdf254ae5da2e0edb388927aa16ec80274d297af75d98f0465247aa8b8512', '56572351-5ab4-4bca-a683-dea844e699d8', '2026-12-01 09:14:19', 2, 'user deleted', NULL, '2026-11-16 09:14:19', '2026-11-16 09:39:35');
INSERT INTO `lc_refresh_token` VALUES (10, 34, '44c02cf6a8e3214115a2d77d2f251244aee1417638a1eec0b22a2acdfaf868ad', '3d35c8cf-1f24-42ea-ad44-36bf680ea9ac', '2026-12-01 09:14:20', 2, 'user deleted', NULL, '2026-11-16 09:14:19', '2026-11-16 09:39:29');
INSERT INTO `lc_refresh_token` VALUES (11, 35, '5d426104d10f59142eca0fa38133bc632c31366ecf136035d664ffb10bae969b', '35c053cd-de26-45ec-87b7-33e5f8c8f978', '2026-12-01 09:14:37', 2, 'user deleted', NULL, '2026-11-16 09:14:36', '2026-11-16 09:39:26');
INSERT INTO `lc_refresh_token` VALUES (12, 36, '66f03d58f0768e41656f483fa386fae312213beb31e0934f256714fb036d1827', 'bde33603-6071-44ef-9d2c-df343bb49c4e', '2026-12-01 09:14:37', 2, 'user deleted', NULL, '2026-11-16 09:14:37', '2026-11-16 09:39:22');
INSERT INTO `lc_refresh_token` VALUES (13, 1, '10dcabf69d61f14c71f0002014dc04ce5c4bc91e460c64555d1cdebfefd920d4', '2f17a77a-b3ab-44a8-97f6-7defaa73e6fe', '2026-12-01 09:21:22', 2, 'logout', NULL, '2026-11-16 09:21:21', '2026-11-16 09:21:36');
INSERT INTO `lc_refresh_token` VALUES (14, 2, 'c6d20381302f16e9eb92250649f7d69df7511086dc376e75ff4933f1a13d71e7', '53665657-48fb-4d0e-af62-783449ee49c8', '2026-12-01 09:21:43', 2, 'logout', NULL, '2026-11-16 09:21:43', '2026-11-16 09:24:11');
INSERT INTO `lc_refresh_token` VALUES (15, 3, '434937ed596b00802608f55d5c4c88e1302c8dc6863918ae7239a12f8d398f2e', 'f960c838-989f-4d7b-986b-73945edc6686', '2026-12-01 09:24:50', 2, 'logout', NULL, '2026-11-16 09:24:50', '2026-11-16 09:26:10');
INSERT INTO `lc_refresh_token` VALUES (16, 3, '9decb0ef3103aca55f2079cc553f4a3acdc8e6bebbe8f0ab9309ff62f7b55e8e', 'f342679c-f797-438e-8580-9428bb178118', '2026-12-01 09:25:28', 2, 'logout', NULL, '2026-11-16 09:25:28', '2026-11-16 09:26:10');
INSERT INTO `lc_refresh_token` VALUES (17, 3, '40d9f398beaeaeede3fc20d564e2321c252d2765f626504d8a9198305b4779de', '2a7a9024-daf3-45b9-bc33-5b5dfc90d6e2', '2026-12-01 09:26:29', 2, 'logout', NULL, '2026-11-16 09:26:29', '2026-11-16 09:27:06');
INSERT INTO `lc_refresh_token` VALUES (18, 2, '89d55784f9cb9874cbd4606d20c348cdbadd4cffc9051e611c0abce949d68a86', 'f7ebf81c-2509-4770-bbe8-9eeb2683bed2', '2026-12-01 09:27:47', 2, 'logout', NULL, '2026-11-16 09:27:46', '2026-11-16 09:36:05');
INSERT INTO `lc_refresh_token` VALUES (19, 3, '4dd06316496f3c0d73811584dba21ffed255698129d8f8879557f6565433c7d3', 'ecbdbc30-6c88-4583-84ae-575ec71cb9df', '2026-12-01 09:36:19', 2, 'logout', NULL, '2026-11-16 09:36:18', '2026-11-16 09:40:17');
INSERT INTO `lc_refresh_token` VALUES (20, 3, '57deac1b963dc3727a65ab550c224ee788a2068fc9a17b8d9e5be91f4b2b99d9', 'f4f22971-e23e-44b9-a17f-d741d079ca50', '2026-12-01 09:36:37', 2, 'logout', NULL, '2026-11-16 09:36:36', '2026-11-16 09:40:17');
INSERT INTO `lc_refresh_token` VALUES (21, 3, '4d59ced264d9ce8b8d320c55648cace59b349c27602bfd842a80f0626c789b8d', '772fa5e2-370e-4048-9da3-379617b24306', '2026-12-01 09:48:56', 0, NULL, NULL, '2026-11-16 09:48:56', '2026-11-16 09:48:56');
INSERT INTO `lc_refresh_token` VALUES (22, 2, '512cf5f0eefc0f1d200cddb2a8cf9a8c62009e4456fee27b41c08f639636b2a6', '1cc242bd-769a-4e3e-ba65-abc154b3f260', '2026-12-08 08:38:06', 2, 'logout', NULL, '2026-11-23 08:38:05', '2026-11-23 08:46:18');
INSERT INTO `lc_refresh_token` VALUES (23, 37, 'a754d097126a2b91d0fd0dc5845071b0f402a3e7332c6d9c32d76320c8b8896c', 'e76052be-65b1-4a98-b098-4def3995a4e4', '2026-12-08 08:39:56', 2, 'logout', NULL, '2026-11-23 08:39:55', '2026-11-23 09:30:54');
INSERT INTO `lc_refresh_token` VALUES (24, 2, '6ed5a72d2c0d9c0de61d8cf53e1a86b10fa6e24c1183cbc3da6429585025a941', '7b819d9b-874f-4157-90df-7658a8a61aaf', '2026-12-08 08:45:47', 2, 'logout', NULL, '2026-11-23 08:45:46', '2026-11-23 08:46:18');
INSERT INTO `lc_refresh_token` VALUES (25, 2, '2ff500dacc4b2b9f35eb9e265f8621b689b02e04927211885a25e40177f5cf55', 'a7c14183-5ec2-424c-ad13-0ee646efb686', '2026-12-08 09:26:59', 2, 'logout', NULL, '2026-11-23 09:26:59', '2026-11-26 14:35:55');
INSERT INTO `lc_refresh_token` VALUES (26, 37, '4bd3faa9f85a4cdabb0fc4684a23f11ca50c43098131f2ef3d52da74ce8460d5', '7dfeed9f-d8b9-45da-89ee-9b664b8e9d7a', '2026-12-08 09:31:09', 2, 'logout', NULL, '2026-11-23 09:31:09', '2026-11-23 09:36:39');
INSERT INTO `lc_refresh_token` VALUES (27, 37, '895dfa29f3268fe46294cf6a1fc6307474a88eeabfaa0f631d035dd13b15dfcd', 'e7b2f4d7-215b-44f7-b43b-2760a015b52c', '2026-12-08 09:44:01', 2, 'logout', NULL, '2026-11-23 09:44:01', '2026-11-26 14:37:10');
INSERT INTO `lc_refresh_token` VALUES (28, 2, '547485bca405f4f3ba5768717d39d2f66b733fe9da5d1f775bc8c29773288423', 'eed6199f-4afc-4989-858c-e9971ba99338', '2026-12-11 13:52:39', 2, 'logout', NULL, '2026-11-26 13:52:39', '2026-11-26 14:35:55');
INSERT INTO `lc_refresh_token` VALUES (29, 37, '734370541b3948bc033bf0ad09980617e90e8a53824aa433faedf20dde52bce7', 'e776fce4-6e2f-4224-add4-fd839de9fee6', '2026-12-11 13:56:09', 2, 'logout', NULL, '2026-11-26 13:56:09', '2026-11-26 14:37:10');
INSERT INTO `lc_refresh_token` VALUES (30, 2, '51d3efe677a9614ae245d2da99856fea6f555278bbe3279aa25cb9e5856924fc', 'f537663c-c7b2-4d6b-9f74-75fa61ac7db1', '2026-12-11 14:36:04', 0, NULL, NULL, '2026-11-26 14:36:03', '2026-11-26 14:36:03');
INSERT INTO `lc_refresh_token` VALUES (31, 37, 'fb2aec7996f30c65f1f560aea2316df947249e7e75f21bda7e1f7e7166b70ab7', 'b618aa50-dca2-48bd-b795-84eec3ff3099', '2026-12-11 14:37:26', 0, NULL, NULL, '2026-11-26 14:37:25', '2026-11-26 14:37:25');
INSERT INTO `lc_refresh_token` VALUES (32, 2, '4e9b22d470d357217e13e2dabb45861ec16ef3223f967261a2d2bf00a3813f9c', 'b27b70b8-da5b-4768-9188-a9c2fa38006a', '2026-12-12 14:00:33', 0, NULL, NULL, '2026-11-27 14:00:33', '2026-11-27 14:00:33');
INSERT INTO `lc_refresh_token` VALUES (33, 3, '45bf9905ffefa55bc40adfc9ff3e20763ee8a1a1f900b797ed0f694fa60fde94', 'b43b473d-c2b8-4f2d-91fb-4419ccd41aec', '2026-12-12 14:18:07', 0, NULL, NULL, '2026-11-27 14:18:06', '2026-11-27 14:18:06');
INSERT INTO `lc_refresh_token` VALUES (34, 3, '9d4ad319c690692efe30770c4735a0e276b88a4d4bae09e92d5a76504768bd73', 'b4025be7-b5f7-46c6-8fff-5c6a67d9548a', '2026-12-12 14:18:40', 0, NULL, NULL, '2026-11-27 14:18:40', '2026-11-27 14:18:40');
INSERT INTO `lc_refresh_token` VALUES (35, 3, '94faf5ef57e6802b464849bdad48c5ff74accda82a8f000ae6ddb69520e0c76c', '24d5f2cf-d1a9-4e1f-b397-82680eace01f', '2026-12-12 14:19:14', 0, NULL, NULL, '2026-11-27 14:19:14', '2026-11-27 14:19:14');
INSERT INTO `lc_refresh_token` VALUES (36, 3, '77d5e58a796ab69cb7b18b2463845dcb1ff1f367ed6b205c56aabeb818dfb138', 'a3e08f3c-1a4c-40ae-b1c8-88bba7c0b18b', '2026-12-12 14:20:14', 0, NULL, NULL, '2026-11-27 14:20:14', '2026-11-27 14:20:14');
INSERT INTO `lc_refresh_token` VALUES (37, 3, 'ce062d9bf5440bf2143e3bddc2a6f6ab807819cba83a180e1fe326a82e1df8cc', '80a3ab2a-2c53-4bf8-9819-c2c7bb2fa0bc', '2026-12-12 14:22:10', 0, NULL, NULL, '2026-11-27 14:22:10', '2026-11-27 14:22:10');
INSERT INTO `lc_refresh_token` VALUES (38, 3, 'd18f691a6e3d22f0816628e72c33656c1cd1e97585fd87e58ba9d0086c6b64b5', '63174d09-47c2-42c7-b711-9884719664fa', '2026-12-12 14:28:37', 0, NULL, NULL, '2026-11-27 14:28:37', '2026-11-27 14:28:37');
INSERT INTO `lc_refresh_token` VALUES (39, 3, '62ae4126302f2a9c8a3b633fc93e1c0a8251f09ad6d712e5cc98727ea5ab7fb3', '390bc7c6-160e-4579-8ec6-711807baf8f2', '2026-12-12 14:30:07', 0, NULL, NULL, '2026-11-27 14:30:07', '2026-11-27 14:30:07');
INSERT INTO `lc_refresh_token` VALUES (40, 3, 'b586ca31f4815c9c278dee63b4da703fcd5d3cf9b4cffe6747a54e622bb8ed66', '94edc7e7-ac52-44d6-894a-e5ef5b40481d', '2026-12-12 14:31:15', 0, NULL, NULL, '2026-11-27 14:31:14', '2026-11-27 14:31:14');
INSERT INTO `lc_refresh_token` VALUES (41, 3, 'c43c327c412548b35270cabd903c3e5b324ef99c9a9ede1f8f655e962071ea2b', '109600f7-e4c9-4b3c-8ebf-d23065d0aa81', '2026-12-12 14:34:30', 0, NULL, NULL, '2026-11-27 14:34:30', '2026-11-27 14:34:30');
INSERT INTO `lc_refresh_token` VALUES (42, 3, '5476e4b4d4389bee66cff22c5240de4ea476031ed88f940cc6f2f50b87751239', '43c22ca2-2b5c-48de-926e-b47d220e04f7', '2026-12-12 14:36:24', 0, NULL, NULL, '2026-11-27 14:36:24', '2026-11-27 14:36:24');
INSERT INTO `lc_refresh_token` VALUES (43, 3, '9b011552a0e3d179ed394b21017ec7aecb910128e0b84007dcd1626c83d5b8ee', '9ae02716-8c86-4aa2-a25e-b1b4410e92da', '2026-12-12 14:37:23', 0, NULL, NULL, '2026-11-27 14:37:23', '2026-11-27 14:37:23');
INSERT INTO `lc_refresh_token` VALUES (44, 3, '40b33e48e64bd0a2520ea0ba38d0610a496ea4bd3657dec73a33a4d2c2a55788', '6e5e73df-1a19-4ca0-9841-93846877d16b', '2026-12-12 14:38:31', 0, NULL, NULL, '2026-11-27 14:38:31', '2026-11-27 14:38:31');

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
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-短信验证码表' ROW_FORMAT = DYNAMIC;

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
) ENGINE = InnoDB AUTO_INCREMENT = 38 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-用户表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- Records of lc_user
-- ----------------------------
INSERT INTO `lc_user` VALUES (1, 'tester01', NULL, '$2a$10$pIiOPkxyO09Di0eqw9yQXu/lmvNUyeNg0UBJgLiViy2fptsOvP4eS', 'tester01', '/uploads/avatars/ff8985bfaa074205a69e84f4b3546365.jpeg', 'user', 1, 2, '2026-11-16 09:21:22', '2026-10-09 14:33:27', '2026-11-16 09:21:21', 1);
INSERT INTO `lc_user` VALUES (2, 'xx', NULL, '$2a$10$KRZ29HhOy1NxsamV46KRL.wlYwTILagT0qUnPCk2w3IIR0qE0N/he', 'xx', '/uploads/avatars/d28efa700b564ccd841bb677d436d3fb.jpeg', 'admin', 1, 1, '2026-11-27 14:00:33', '2026-10-28 16:25:05', '2026-11-27 14:00:33', 0);
INSERT INTO `lc_user` VALUES (3, 'admin', NULL, '$2a$10$fZZ0GOgwjyUpD4bGVPhS8OZHaZp6DdRHMy9EeB8KGgXlrTjhuWP0i', '超级管理员', '/uploads/avatars/09953a16f3dd4064aa2d72ac4011f946.jpeg', 'admin', 1, 1, '2026-11-27 14:38:31', '2026-10-28 16:56:11', '2026-11-27 14:38:31', 0);
INSERT INTO `lc_user` VALUES (4, 'cc', NULL, '$2a$10$8iFeImcuRP32nl23AHR64OKxUcJ.mQzz2LvvzjvDKWjarLm.Dg1bu', 'cc', '/uploads/avatars/b962b99c0a644439a5e8cc9e2f7bf4c2.jpeg', 'user', 1, 1, '2026-11-16 09:01:36', '2026-10-28 23:10:05', '2026-11-16 09:01:36', 1);
INSERT INTO `lc_user` VALUES (29, 'upload_test_01', NULL, '$2a$10$JlBIqQwV7nILWT6H.RqA5O6LsOxX8THSbfj6U03KEjm8mEY5IVOCS', 'upload_test_01', '/uploads/avatars/a1a72b556a4449e680964674717a3dc5.png', 'user', 1, 1, '2026-11-12 15:05:47', '2026-11-12 13:54:48', '2026-11-12 15:05:47', 1);
INSERT INTO `lc_user` VALUES (30, 'upload_test_02', NULL, '$2a$10$u.OZ4wuThurQig1JetAtEumRlNEH065seGePQuIyjamsjvDtj3glW', 'upload_test_02', NULL, 'user', 1, 1, '2026-11-12 14:39:14', '2026-11-12 14:39:01', '2026-11-12 14:39:14', 1);
INSERT INTO `lc_user` VALUES (37, '55', NULL, '$2a$10$xVg4PjBJ3VYeYcMTWPy9TOwmKNXdd/D35oYga9X8yPBGCM5vXlij2', '55', '/uploads/avatars/d1cb00d640b646d2881eb7933848d614.png', 'user', 1, 1, '2026-11-26 14:37:26', '2026-11-23 08:39:45', '2026-11-26 14:37:25', 1);

SET FOREIGN_KEY_CHECKS = 1;
