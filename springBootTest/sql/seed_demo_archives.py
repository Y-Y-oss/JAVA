# -*- coding: utf-8 -*-
"""
时光代理人 · 演示数据种子脚本
用法：
  python seed_demo_archives.py
说明：
  - 往 lc_user 插入演示用户 linkclick（密码 123456，BCrypt 哈希已在项目中提供）
  - 往 lc_archive 插入 10 条时光档案（覆盖 私语/信件/告白/约定 标签 + 不同日期 + 公开/私有）
  - 前 6 条档案 id 为 1~6，正好对应前端 public/img/archives/1~6.png 封面
  - 公开档案会出现在社区「档案墙」(/api/archives/public)
  - 幂等：若 lc_archive 已有数据则跳过插入，避免重复。
"""
import pymysql

DB = dict(host="127.0.0.1", port=3306, user="root", password="123456",
          database="link_click_auth", charset="utf8mb4")

# 项目中已给出的 123456 的 BCrypt 哈希（可直接落库）
DEMO_HASH = "$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi"

conn = pymysql.connect(**DB)
cur = conn.cursor()

try:
    # 1) 确保档案表存在（极端情况下库表未初始化时兜底）
    cur.execute("""
        CREATE TABLE IF NOT EXISTS `lc_archive` (
            `id`           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
            `user_id`      BIGINT UNSIGNED NOT NULL,
            `title`        VARCHAR(100)    NOT NULL,
            `content`      TEXT,
            `archive_date` DATE            DEFAULT NULL,
            `tag`          VARCHAR(30)     DEFAULT NULL,
            `visibility`   TINYINT         NOT NULL DEFAULT 0,
            `create_time`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `update_time`  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_lc_archive_user` (`user_id`),
            KEY `idx_lc_archive_public` (`visibility`, `update_time`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
    """)

    # 2) 演示用户 linkclick（密码 123456），已存在则忽略
    cur.execute(
        "INSERT IGNORE INTO `lc_user` "
        "(`username`,`phone`,`password`,`nickname`,`role`,`status`,`pwd_version`) "
        "VALUES (%s,%s,%s,%s,%s,1,1)",
        ("linkclick", "13800000000", DEMO_HASH, "时光代理人", "user"),
    )

    def uid(name):
        cur.execute("SELECT id FROM `lc_user` WHERE username=%s", (name,))
        r = cur.fetchone()
        return r[0] if r else None

    linkclick_id = uid("linkclick")
    xx_id = uid("xx")
    cc_id = uid("cc")
    print(f"用户 id -> linkclick={linkclick_id}, xx={xx_id}, cc={cc_id}")

    # 3) 幂等：已有档案则不重复插入
    cur.execute("SELECT COUNT(*) FROM `lc_archive`")
    if cur.fetchone()[0] > 0:
        print("lc_archive 已有数据，跳过演示数据插入（如需重置请先 DELETE FROM lc_archive）。")
        conn.commit()
        raise SystemExit(0)

    # 4) 插入演示档案。注意：linkclick 的 6 条先插，拿到 id 1~6 以匹配封面图。
    rows = []
    # —— linkclick 的 6 条（公开/私有混合，覆盖 4 个标签）——
    rows += [
        (linkclick_id, "雨中私语", "那天下着小雨，我们在屋檐下躲雨，谁都没有说话，却比任何时候都安心。", "2019-04-12", "私语", 1),
        (linkclick_id, "未寄出的信", "写了一封永远不会寄出的信，收信人是我们都认识的那个夏天。", "2020-03-08", "信件", 0),
        (linkclick_id, "天台上的告白", "天台的风很大，我鼓起勇气说出了藏了三年的话，你笑了。", "2021-07-19", "告白", 1),
        (linkclick_id, "时光闭锁", "我们说好无论走多远，都要在每年的这一天回到这里。", "2022-08-25", "约定", 0),
        (linkclick_id, "平安夜的路灯", "平安夜的路灯把影子拉得很长，你哼着跑调的歌，我偷偷记下了旋律。", "2019-12-24", "私语", 1),
        (linkclick_id, "山顶看日出", "凌晨四点爬上山顶，云海翻涌的那一刻，所有等待都值得了。", "2023-05-01", "约定", 1),
    ]
    # —— xx 的 2 条（公开，丰富社区墙）——
    if xx_id:
        rows += [
            (xx_id, "旧书店的邂逅", "在二手书店的角落同时伸手碰到同一本书，像是被时光安排好的相遇。", "2020-09-10", "信件", 1),
            (xx_id, "情人节乌龙", "把告白短信错发给了老妈，她回了一句‘加油儿子’，场面一度失控。", "2022-02-14", "告白", 1),
        ]
    # —— cc 的 2 条（1 公开 1 私有，演示私有不上墙）——
    if cc_id:
        rows += [
            (cc_id, "毕业那年的蝉鸣", "操场边的蝉鸣停不下来，我们拍完合影，各自奔向没有彼此的城市。", "2018-06-15", "私语", 1),
            (cc_id, "国庆骑行", "说好三人同行，结果半路爆胎，推着车走了十里路也笑得开心。", "2021-10-01", "约定", 0),
        ]

    sql = ("INSERT INTO `lc_archive` "
           "(`user_id`,`title`,`content`,`archive_date`,`tag`,`visibility`) "
           "VALUES (%s,%s,%s,%s,%s,%s)")
    cur.executemany(sql, rows)
    conn.commit()
    print(f"已插入 {len(rows)} 条演示档案（linkclick 前 6 条 id=1~6，对应首页封面图）。")
    print("登录演示账号：linkclick / 123456  （或你已注册的 xx / cc）")
finally:
    cur.close()
    conn.close()
