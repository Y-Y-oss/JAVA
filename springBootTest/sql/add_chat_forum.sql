-- =====================================================================
-- 增量脚本：好友聊天 + 论坛
-- 对应功能：导航栏头像旁的「好友聊天」「论坛」面板
-- 库：link_click_auth（可重复执行：先 DROP 再 CREATE）
-- =====================================================================

SET NAMES utf8mb4;

-- ----------------------------
-- 1. 好友私信表（好友一对一聊天记录）
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
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-好友私信表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- 2. 论坛帖子表
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
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-论坛帖子表' ROW_FORMAT = DYNAMIC;

-- ----------------------------
-- 3. 论坛回复表
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
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci COMMENT = '时光代理人-论坛回复表' ROW_FORMAT = DYNAMIC;
