# -*- coding: utf-8 -*-
"""
端到端冒烟测试：好友聊天 + 论坛（link_click_auth 后端 8081）
流程：注册两个测试号 → 登录 → 加好友/通过验证 → 私聊/未读 → 论坛发帖/回复/删除
用法：python e2e_chat_forum_test.py
"""
import json
import re
import time
import urllib.request

BASE = "http://127.0.0.1:8081/api"
LOG = r"D:/workSpace/JAVA/springBootTest/log/xx.log"
results = []


def call(method, path, body=None, token=None):
    url = BASE + path
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("Content-Type", "application/json;charset=utf-8")
    req.add_header("Accept", "application/json")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        try:
            return json.loads(e.read().decode("utf-8"))
        except Exception:
            return {"code": e.code, "message": "HTTP %s" % e.code}


def check(name, ok, detail=""):
    results.append((name, ok, detail))
    print(("PASS  " if ok else "FAIL  ") + name + ("  | " + str(detail) if detail and not ok else ""))


def register_and_login(username):
    # 1. 取图形验证码
    cap = call("GET", "/auth/captcha")
    captcha_id = cap["data"]["captchaId"]
    # 2. 从日志里捞该 captchaId 的答案（auth 服务把答案打到了 xx.log）
    code = None
    for _ in range(10):
        time.sleep(0.3)
        with open(LOG, encoding="utf-8", errors="ignore") as f:
            m = re.findall(r"captchaId=%s, code=([A-Za-z0-9]+)" % re.escape(captcha_id), f.read())
        if m:
            code = m[-1]
            break
    assert code, "日志里没找到验证码答案"
    # 3. 注册
    r = call("POST", "/auth/register", {
        "username": username, "password": "Test12345", "confirmPassword": "Test12345",
        "captchaId": captcha_id, "captchaCode": code,
    })
    check("注册 %s" % username, r.get("code") == 200, r)
    # 4. 登录拿 token
    r = call("POST", "/auth/login", {"account": username, "password": "Test12345"})
    check("登录 %s" % username, r.get("code") == 200, r)
    token = (r.get("data") or {}).get("accessToken") or (r.get("data") or {}).get("token")
    uid = ((r.get("data") or {}).get("user") or {}).get("id") or (r.get("data") or {}).get("id")
    return token, uid


def main():
    suffix = str(int(time.time()))[-6:]
    user_a, user_b = "e2ea" + suffix, "e2eb" + suffix

    token_a, uid_a = register_and_login(user_a)
    token_b, uid_b = register_and_login(user_b)
    if not (token_a and token_b):
        print("登录失败，中止"); return

    # ---- 好友：A 申请 → B 同意 ----
    r = call("POST", "/friends/apply", {"username": user_b}, token_a)
    check("A 向 B 发好友申请", r.get("code") == 200, r)
    r = call("GET", "/friends/pending", token=token_b)
    pending = r.get("data") or []
    apply_id = pending[0]["id"] if pending else None
    check("B 看到待验证申请", apply_id is not None, r)
    r = call("POST", "/friends/apply/%s/accept" % apply_id, {}, token_b)
    check("B 通过验证", r.get("code") == 200, r)
    r = call("GET", "/friends", token=token_a)
    check("A 的好友列表含 B", any(f.get("username") == user_b for f in (r.get("data") or [])), r)

    # ---- 聊天 ----
    r = call("POST", "/chat/%s/messages" % uid_b, {"content": "你好，我是 A"}, token_a)
    check("A 给 B 发私信", r.get("code") == 200, r)
    r = call("GET", "/chat/unread", token=token_b)
    check("B 未读数=1", (r.get("data") or {}).get("total") == 1, r)
    r = call("GET", "/chat/%s/messages" % uid_a, token=token_b)
    msgs = r.get("data") or []
    check("B 拉到聊天记录(1条)", len(msgs) == 1 and msgs[0]["content"] == "你好，我是 A", r)
    r = call("GET", "/chat/unread", token=token_b)
    check("拉历史后自动已读 未读数=0", (r.get("data") or {}).get("total") == 0, r)
    r = call("POST", "/chat/%s/messages" % uid_a, {"content": "你好 A，我是 B"}, token_b)
    check("B 回复 A", r.get("code") == 200, r)
    r = call("GET", "/chat/%s/messages" % uid_b, token=token_a)
    msgs = r.get("data") or []
    check("A 拉到两条消息(时间正序)", len(msgs) == 2 and msgs[0]["senderId"] == uid_a, r)
    r = call("GET", "/chat/conversations", token=token_a)
    conv = r.get("data") or []
    target = [c for c in conv if c.get("username") == user_b]
    # A 在上一步拉过历史，后端已自动把 B 的回复标为已读，所以这里未读应为 0，且最近一条消息应为 B 的回复
    check("A 会话总览含 B 且最近消息正确(已读=0)",
          target and target[0].get("unread") == 0 and target[0].get("lastContent") == "你好 A，我是 B", r)

    # ---- 论坛 ----
    r = call("POST", "/forum/posts", {"title": "冒烟测试帖", "content": "大家好，这是端到端测试的帖子。"}, token_a)
    check("A 发布帖子", r.get("code") == 200, r)
    post_id = (r.get("data") or {}).get("id")
    r = call("GET", "/forum/posts?page=1&size=5")
    check("游客可浏览帖子列表", r.get("code") == 200 and any(p["id"] == post_id for p in (r.get("data") or {}).get("records", [])), r)
    r = call("POST", "/forum/posts/%s/replies" % post_id, {"content": "沙发！来自 B 的回复"}, token_b)
    check("B 回复帖子", r.get("code") == 200, r)
    r = call("GET", "/forum/posts/%s" % post_id)
    d = r.get("data") or {}
    check("详情含回复且回复数=1", d.get("replyCount") == 1 and len(d.get("replies") or []) == 1, r)
    reply_id = (d.get("replies") or [{}])[0].get("id")
    r = call("DELETE", "/forum/replies/%s" % reply_id, token=token_a)
    check("A 删别人的回复被拒(403)", r.get("code") == 403, r)
    r = call("DELETE", "/forum/replies/%s" % reply_id, token=token_b)
    check("B 删自己的回复", r.get("code") == 200, r)
    r = call("DELETE", "/forum/posts/%s" % post_id, token=token_a)
    check("A 删自己的帖子", r.get("code") == 200, r)

    # ---- 汇总 ----
    fails = [n for n, ok, _ in results if not ok]
    print("\n===== 结果：%d 项通过，%d 项失败 =====" % (len(results) - len(fails), len(fails)))
    if fails:
        print("失败项：", fails)


if __name__ == "__main__":
    main()
