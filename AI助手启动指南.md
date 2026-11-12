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
# 1. MySQL(服务名 MySQL80;客户端在 C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe)
net start MySQL80

# 2. 仅当库不存在时建库(脚本幂等,但会重建 lc_sms_code / lc_refresh_token,别每次跑)
"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" -uroot -p123456 \
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

5. **机器重置会清空前端 `node_modules`**（同 `target`）→ 表现为"整站起不来",但后端/MySQL 往往还在跑。
   一键脚本 `启动项目.bat` 已自动处理:检测到 `link-click-auth-vue\node_modules` 缺失时会先 `npm ci`(约 1-2 分钟,**此期间前端窗口看似卡住属正常**),再起 Vite。
   手动启动时务必先 `cd link-click-auth-vue && npm ci`(或 `npm install`)再 `npm run dev`,否则 5173 起不来。
   验证前端真起来了:`curl http://localhost:5173/api/auth/captcha` 期望 `code:200`(走 /api→8081 代理)。

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

## 后台管理系统(Admin)

- 入口:`http://localhost:8081/admin/index.html`(后端 Spring Boot 直接托管的静态页面,**不是** `link-click-web` 那个空壳 index.html)。前端 `/admin` 已代理到 8081,所以社区页导航的"后台管理"也能直达。
- 可见性 / 可登录性统一由 `lc_user.permission` 决定:`permission=0` 或 `role='admin'` 才放行(`AuthServiceImpl.requireAdmin` 与前端 `NavBar` 都按此判断)。
- 2026-11-05 修过一个致命漂移:`lc_user` 表缺 `permission` 列 → 所有 `/api/admin/**` 报 `Unknown column 'permission'`、导航后台入口也看不见。已执行
  `ALTER TABLE lc_user ADD COLUMN permission TINYINT NOT NULL DEFAULT 1 ...` 并把 `admin` 账号置为 `permission=0`。**以后若新建管理员,只要确保这两点之一即可。**

## 2026-11-12 新增/修复(别改回去)

1. **照片上传根因修复**:`ArchiveController` 的 `MultipartFile.transferTo()` 传相对路径会被 Tomcat 解析到它自己的临时工作目录(报「文件保存失败」)。已加 `resolveUploadRoot()` 统一转绝对路径(upload / deleteUpload / deleteCoverFileIfUploaded 三处)——**千万别改回相对路径**。
2. **前端 request.js 的 `del(url, params)` 支持 query 参数**(此前第二参被丢弃,DELETE /archives/upload?url= 必 400)。
3. **社区互动功能**:新表 `lc_archive_like` / `lc_archive_favorite` / `lc_archive_comment`(在 sql 脚本末尾,幂等);新 `SocialController`(/api/social:点赞切换/收藏切换/互动汇总/评论增删);档案墙 SQL 带 like_count/favorite_count/comment_count 子查询,**且 selectPublicWall 现在查了 cover 列**(别删)。
   前端:`api/social.js`、ArchiveCard 的 `interactive` 互动栏、ArchiveDetail 评论区。
4. **五子棋双模式**:GomokuGame.vue 顶部可切「🤖人机 / 👥双人」,切换即重开。
5. **B 站板块真实封面**:已下载到 `link-click-auth-vue/public/img/bili/`(overview/s1/s2/s3/extra.png),Community.vue 直接引用本地文件;番剧 ID:总览 md28230742、一季 ss35220、二季 ss39666、三季 ss105212。
6. MySQL 客户端真实路径是 **8.0**(本文档前面已更正);测试账号 `upload_test_01 / Test123456`(userId=29),含公开演示档案 id=10002。

## 账号持久化(安全结论)

- `sql/link_click_auth.sql` 是安全的:用户表 `lc_user` 用 `CREATE TABLE IF NOT EXISTS` + information_schema 探测,**不会 DROP 用户表**;只有 `lc_sms_code` / `lc_refresh_token` 会重建。增量 ALTER 只补缺失列。
- 没有 `ddl-auto` / `schema.sql` / `data.sql`,MyBatis-Plus 不自动重建表,所以**重新导入 SQL 不会清空已有账号**。当前库里 4 个账号(含 `admin`)均持久保留。
- 真正要防的"账号丢失"来自两点:① 机器重置只清 `node_modules`/`target`,不动 MySQL 数据文件,账号不会丢;② 改 `sql` 脚本千万别给用户表加 `DROP`。

## 启动脚本结构(2026-11-05 重构)

**"双击 启动项目.bat 闪退/没反应"的根因**:旧版脚本用
`start "T" /D "dir" cmd /k "call "%MVN_CMD%" -q spring-boot:run & ..."`
——**引号套引号**,cmd 收到的命令行被打碎,后端窗口开了但命令是坏的 → 后端永远起不来 → 主脚本卡在「等待后端就绪」静默空转最多 3 分钟,表现就是"打不开 / 闪退"。

现在的结构(刻意避免任何嵌套引号):

| 文件 | 职责 |
|---|---|
| `启动项目.bat` | 入口:检查 MySQL / 建库 / 判断端口 / 拉起子脚本 / 等后端就绪(每秒打点) / 自动开浏览器 |
| `scripts\run-backend.bat` | 后端窗口:`call "%MVN_CMD%" spring-boot:run`,失败会停住显示报错 |
| `scripts\run-frontend.bat` | 前端窗口:`npm ci`(缺 node_modules 时)+ `npm run dev`,失败会停住 |

要点:
- 子脚本只用**一层**引号:`start "标题" /D "目录" cmd /k "完整路径\xxx.bat"`。
- **不要**再往 `cmd /k "..."` 里塞第二对引号(如 `call "..."`),这是旧版崩溃的原因。
- 三个 `.bat` 必须保存为 **GBK + CRLF + 无 BOM**;存成 UTF-8 会让 cmd 按字节错配引号。
- 已在运行则跳过,避免无谓重启;强制重启用 `启动项目.bat restart`。
- 自动跳过暂停用 `启动项目.bat nopause`(自动化场景)。
- 排错先看同目录 **`启动日志.txt`**,最后一行就是卡住的步骤。
- 沙箱/CI 里 `cmd.exe` 可能被禁用,此时无法自动化跑 bat,只能验证其依赖命令(`mvnw`、`npm`)本身可用。
