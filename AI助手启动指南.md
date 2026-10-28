# AI 助手启动指南 —— 时光代理人 Link Click

> 写给 AI 助手:这台电脑**每次开机都重置**(删除 node_modules 和 target)。
> 用户让你"启动项目"时,**先读本文件,直接照做,不要重新排查**。
> 以下结论已于 2026-10-12 全部实测验证。

## 一键操作(优先用这个,别再手动拼命令)

- 启动:运行本目录 `启动项目.bat`(自动化执行时加参数 `nopause` 避免卡在 pause)
- 停止:`停止项目.bat`
- 脚本已处理:清环境变量坑 → 检查 MySQL → 缺库自动建库 → 起后端 → 自动 npm ci → 起前端 → 健康检查

## 项目结构

| 模块 | 目录 | 端口 | 启动 |
|---|---|---|---|
| 前端 Vue3 + Vite | `link-click-auth-vue/` | 5173 | `npm run dev`(vite.config.js 已配 /api → 8081 代理) |
| 后端 Spring Boot 3.4.5 | `springBootTest/` | 8081 | `mvn spring-boot:run`(profile=dev) |
| MySQL 8 | 服务名 `MySQL80` | 3306 | 库 `link_click_auth`,root / 123456 |

## 手动启动(脚本失效时的降级方案,按顺序)

```bash
# 1. MySQL(服务名 MySQL80;客户端在 C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe)
net start MySQL80

# 2. 仅当库不存在时建库(脚本幂等,但会重建 lc_sms_code / lc_refresh_token,别每次跑)
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -uroot -p123456 \
  --default-character-set=utf8mb4 < springBootTest/sql/link_click_auth.sql

# 3. 后端(Maven 不在 PATH;二选一;关键:必须去掉 SERVER__PORT!)
cd springBootTest && env -u SERVER__PORT ./mvnw.cmd -q spring-boot:run

# 4. 前端(node_modules 已被重置删除,必须先装依赖)
cd link-click-auth-vue && npm ci --no-audit --no-fund && npm run dev
```

## 关键坑(都踩过,别再踩)

1. **`SERVER__PORT=63302`**:WorkBuddy 终端环境变量,会被 Spring Boot relaxed binding 当成 `server.port`,顶掉 8081 → 前端代理 500。bash 里用 `env -u SERVER__PORT`;bat 里已 `set "SERVER__PORT="`。在 IDEA 里跑不受影响。
2. **「系统繁忙」= 数据库没连上**(多半是库不存在),不是验证码问题;「账号或密码错误」才是 DB 正常的标志。
3. Maven 不在 PATH。~~IDEA 自带 maven3 路径已失效(2026-10-29 确认 `D:\IntelliJ IDEA 2024.3.2.2` 下无 Maven)~~ **统一用项目内 `./mvnw.cmd`**,wrapper 缓存在 `~/.m2/wrapper/dists/apache-maven-3.9.9*`,完好可用。Java 17 在 PATH。
4. 图形验证码存内存不落库,**后端一重启全部验证码失效,属正常现象**,不是 bug。

## 已修过的问题(别改回去)

- `application.properties` 日志包名已修为 `logging.level.com.fenglin.springboottest=debug`(原来是 `com.fenglin.springboot`,Logback 包层级匹配不上)→ 图形验证码答案可在 `springBootTest/log/xx.log` 里 grep "图形验证码已生成" 看到。
- 数据库 `link_click_auth` 已建,4 张表:lc_user / lc_sms_code / lc_refresh_token / lc_archive。
- 2026-10-12:前端登录已从"假登录"接通后端。`LoginForm.vue` 真调 `/auth/login`;`src/api/session.js` 管 token 存储(记住我→localStorage,否则 sessionStorage);`request.js` 通过 `setTokenProvider` 自动带 Authorization;`App.vue` 登录后显示用户视图(头像/昵称/退出),刷新时用 `/auth/profile` 恢复登录态,登出调 `/auth/logout`。

## 健康检查(判断"好了没")

```bash
# 后端出图(纯内存,不依赖 DB)
curl http://localhost:8081/api/auth/captcha
# 期望:{"code":200,...,"image":"data:image/png;base64,..."}

# DB 连通(登录接口会查库)
curl -X POST http://localhost:8081/api/auth/login -H "Content-Type: application/json" \
  -d '{"account":"healthcheck_none","password":"x12345"}'
# 期望:{"code":500,"message":"账号或密码错误"} —— 说明 DB 通了

# 前端代理
curl http://localhost:5173/api/auth/captcha   # 同样 code:200
```

## 架构备注(避免重复读源码)

- 验证码:后端 `CaptchaServiceImpl` AWT 画图 + 内存 Map(120 秒、一次性消费),答案只写 DEBUG 日志不下发;前端 `GraphicCaptcha.vue` 挂在 `RegisterForm.vue` 的 `.captcha-slot`。
- 登录:双令牌,accessToken(JWT)+ refreshToken(轮换,SHA-256 摘要落 `lc_refresh_token`)。
- 前端无 axios,`src/api/request.js` 是 fetch 封装,BASE_URL=/api。
