# 时光代理人 · 后端服务（springBootTest）

对应前端项目：`D:\workSpace\JAVA\link-click-auth-vue`

> 本项目是「时光代理人」的后端，包含三大块：
> 1. **账号鉴权** —— 注册 / 登录 / 改密 / 角色权限（核心底座）
> 2. **时光档案** —— 核心业务，用户记录属于自己的回忆档案，可公开到「档案墙」
> 3. **管理后台** —— 仅管理员可用，管理用户与档案（配套静态页面 `static/admin/index.html`）

---

## 1. 技术栈

| 组件 | 版本 / 说明 |
| --- | --- |
| Spring Boot | 3.4.5（Java 17） |
| 数据库 | MySQL 8.x |
| 数据库层 | MyBatis-Plus 3.5.5（`mybatis-plus-spring-boot3-starter`） |
| 连接池 | HikariCP |
| 参数校验 | spring-boot-starter-validation |
| 密码加密 | spring-security-crypto（BCrypt，强度 10）—— **注意：当前鉴权流程并未调用它**，注册/登录/改密均为「明文存储 + 明文比对」，`BCryptPasswordEncoder` 这个 Bean 已定义但未被使用（见下方「已知问题」） |
| 鉴权 | JWT（自包含 token + 密码版本号 `pwd_version` 踢人机制） |

---

## 2. 建库建表

完整建表脚本在项目内，有两个副本（内容一致），任选其一执行即可：

- 根目录：`link_click_auth.sql`（约 12KB，**推荐**，含全部表）
- 子目录：`sql/link_click_auth.sql`

```bash
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -uroot -p123456 < link_click_auth.sql
```

```sql
mysql -uroot -p123456
mysql> source D:/workSpace/JAVA/springBootTest/sql/link_click_auth.sql;
```

涉及的数据表：

| 表 | 说明 |
| --- | --- |
| `lc_user` | 用户表。`username`、`phone` 各自唯一；密码存 BCrypt 哈希；含 `role`（user/admin）、`permission`（0-管理员/1-普通）、`status`（0-禁用/1-正常）、`pwd_version`（改密踢人用） |
| `lc_sms_code` | 短信验证码，`expire_time` 控制有效期，`consumed` 标记是否已使用 |
| `lc_archive` | 时光档案，`user_id` 关联用户，`visibility`（0-仅自己/1-公开），含标题/内容/时光节点/标签 |
| `lc_refresh_token` | 刷新令牌，支持吊销（禁用用户/重置密码/删除用户时联动吊销） |

> 管理后台与档案功能依赖上述全部表与字段。**只建了 `lc_user`/`lc_sms_code` 的旧库会跑不起来**，务必执行完整脚本。

---

## 3. 接口

统一返回结构：`{ "code": 200, "message": "...", "data": {}, "errors": {} }`（`code != 200` 即失败，`errors` 为字段级错误）。

### 3.1 发送验证码

```
GET /api/auth/send-code?phone=13800000001&scene=register
```

| 参数 | 必填 | 说明 |
| --- | --- | --- |
| phone | 是 | 11 位手机号 |
| scene | 否 | 验证码场景：`register`（注册，默认）、`reset_password`（重置密码）；传其他值会被拒绝 |

各场景的验证码互不干扰（限频、历史清理都按场景隔离），同一手机号可以同时持有「注册码」和「重置码」。

成功响应：

```json
{
  "code": 200,
  "message": "验证码已发送，请注意查收",
  "data": { "phone": "13800000001", "scene": "register", "expireSeconds": 300, "resendSeconds": 60, "code": "777237" }
}
```

> `data.code` 只在演示模式（`auth.sms.debug=true`）下返回，方便本地联调；生产环境置为 `false` 即可。
> 限制：同一手机号**同一场景** 60 秒内只能发一次（`auth.sms.resend-interval-seconds`），验证码 5 分钟过期（`auth.sms.code-expire-seconds`）。

### 3.2 注册

```
POST /api/auth/register
Content-Type: application/json

{
  "username": "linkclick01",
  "phone": "13800000001",
  "code": "777237",
  "password": "123456",
  "confirmPassword": "123456"
}
```

成功响应：

```json
{
  "code": 200,
  "message": "注册成功，欢迎成为时光代理人",
  "data": { "id": 1, "username": "linkclick01", "phone": "13800000001", "nickname": "linkclick01" }
}
```

失败示例：

```json
{ "code": 500, "message": "该用户名已被占用", "errors": { "username": "该用户名已被占用" } }
{ "code": 500, "message": "参数校验失败，请检查表单", "errors": { "password": "密码需 6-20 位", "code": "验证码为 6 位数字" } }
```

### 3.3 登录

```
POST /api/auth/login
Content-Type: application/json

{ "account": "lc_demo", "password": "timepass" }
```

`account` 既可以填用户名，也可以填手机号。成功响应：

```json
{
  "code": 200,
  "message": "登录成功，正在穿越时光…",
  "data": {
    "token": "eyJhbGciOiJIUzUxMiJ9...",
    "tokenType": "Bearer",
    "expiresIn": 604800,
    "id": 3, "username": "lc_demo", "phone": "13611112222", "nickname": "lc_demo"
  }
}
```

前端的存储策略：勾选「记住我」写 `localStorage['lc_token']`（长期），否则写 `sessionStorage`（关闭标签页即失效），
后续请求由 `src/api/request.js` 自动带上 `Authorization: Bearer xxx`；点「退出」会先调 `/api/auth/logout`
把 token 拉黑，再清掉本地凭证。

### 3.4 获取当前登录用户

```
GET /api/auth/profile
Authorization: Bearer xxxxx
```

```json
{ "code": 200, "message": "操作成功", "data": { "id": 3, "username": "lc_demo", "phone": "13611112222", "nickname": "lc_demo" } }
```

失败：`{"code":401,"message":"登录已过期或凭证无效，请重新登录"}`（token 过期/被篡改）、
`{"code":401,"message":"未携带登录凭证，请重新登录"}`（请求头缺失）、
`{"code":500,"message":"登录状态已失效，请重新登录"}`（该 token 已经退出登录）。

### 3.5 退出登录

```
POST /api/auth/logout
Authorization: Bearer xxxxx
```

把当前 token 加入服务端黑名单，之后即便请求头还带着它也会被拒绝（提示「登录状态已失效」）。
黑名单存在应用内存中（重启即清空，用户需重新登录），每小时自动清理过期记录；
生产环境建议换成 Redis 的 Set + TTL。

### 3.6 重置密码

```
POST /api/auth/reset-password
Content-Type: application/json

{
  "phone": "13611112222",
  "code": "733632",
  "password": "newpass123",
  "confirmPassword": "newpass123"
}
```

成功响应：

```json
{ "code": 200, "message": "密码已重置，请使用新密码登录", "data": { "id": 1, "username": "lc_demo", "phone": "13611112222" } }
```

前置条件与失败提示：

| 场景 | 提示 |
| --- | --- |
| 手机号未注册 | `该手机号尚未注册，请前往注册` |
| 手机号格式不对 | `请输入正确的 11 位手机号` |
| 两次密码不一致 | `两次输入的密码不一致`（`errors.pwd2`） |
| 新密码与旧密码相同 | `新密码不能与当前密码相同，请换一个` |
| 验证码错误 / 已使用 / 已过期 | `验证码错误，请重新输入` / `验证码不存在或已过期，请重新获取` |

顺序上先做密码相关校验、再消费验证码，失败时验证码仍可重复使用；重置成功后旧密码立即失效，
该手机号尚未签发的 token 不受影响（仍可在到期前使用）。

### 3.7 修改昵称

```
PUT /api/auth/profile
Authorization: Bearer xxxxx
Content-Type: application/json

{ "nickname": "时光代理人小李" }
```

```json
{ "code": 200, "message": "资料已更新", "data": { "id": 1, "username": "lc_demo", "phone": "13611112222", "nickname": "时光代理人小李" } }
```

用户名和手机号是登录凭据，不支持在这里改（改手机号需要走短信验证流程）。空昵称会被参数校验拦下，
返回 `{"code":500,"message":"参数校验失败，请检查表单","errors":{"nickname":"请输入昵称"}}`。

### 3.8 修改密码

```
POST /api/auth/change-password
Authorization: Bearer xxxxx
Content-Type: application/json

{ "oldPassword": "timepass", "newPassword": "newpass123", "confirmPassword": "newpass123" }
```

| 场景 | 提示 |
| --- | --- |
| 当前密码错误 | `当前密码错误` |
| 两次输入不一致 | `两次输入的密码不一致`（`errors.confirmPassword`） |
| 新密码与当前密码相同 | `新密码不能与当前密码相同，请换一个` |
| 新密码位数不足 | `参数校验失败…`（`errors.newPassword`） |

成功后返回 `密码已修改，其他设备的登录状态已失效，请用新密码重新登录`。

#### 密码版本号：为什么改密后所有人都得重新登录

JWT 是自包含的，只要没过期就一直能用——所以「用户改了密码，但攻击者手上的 token 还能用到 7 天后」
是个真实存在的漏洞。这里用密码版本号解决：

1. `lc_user` 增加 `pwd_version` 列，签发 token 时把当前版本号写进 claim `pv`
2. 每次鉴权都拿 token 里的 `pv` 和数据库里的 `pwd_version` 比对，不一致就拒绝
3. 修改密码 / 重置密码时 `pwd_version = pwd_version + 1`

这样服务端不需要存任何会话状态，就能做到「改密瞬间踢掉所有设备」。同一机制也能用于后续加「强制下线」。

### 3.9 角色与授权

角色存在 `lc_user.role`（`user` 普通用户 / `admin` 管理员），签发 token 时会写进 claim `role`，
`/api/auth/profile` 与登录响应都会返回。角色由管理员在数据库里调整，**用户自己改不了**
（这也是为什么 `PUT /api/auth/profile` 只开放昵称）。

`AuthService#checkRole(token, 所需角色...)` 是统一的校验入口：

| 情况 | 响应 |
| --- | --- |
| 没带 token | `{"code":401,"message":"未携带登录凭证，请重新登录"}` |
| token 过期 / 被篡改 | `{"code":401,"message":"登录已过期或凭证无效，请重新登录"}` |
| 有登录但角色不够 | `{"code":403,"message":"权限不足，该操作需要「管理员」角色"}` |
| 通过 | 正常返回业务数据 |

演示接口（见 `controller/DemoController`）：

```
GET /api/demo/archives          任意登录用户可读
GET /api/demo/archives/all      仅管理员可读（含机密档案）
```

角色判断以**数据库里的值**为准（不是 token 里的），所以直接改 `lc_user.role` 后，
已登录用户下一次请求就生效，不需要重新登录；反过来，伪造 token 里的 `role` claim
会在签名校验阶段就被拒掉。

> 真实项目更推荐用 Spring Security 的 `@PreAuthorize("hasRole('ADMIN')")` 或 AOP 切面，
> 这里手写 `checkRole` 是为了让校验过程一目了然。

### 3.10 校验规则

| 字段 | 规则 |
| --- | --- |
| username | 2-20 位，中英文/数字/下划线/中划线，全局唯一 |
| phone | `^1[3-9]\d{9}$`；重置密码场景下还要求该手机号已注册 |
| code | 6 位数字，5 分钟内有效，一次性使用 |
| password | 6-20 位；**当前实现为明文存储/明文比对，并未经 BCrypt 加密**（存在安全隐患，见「已知问题」）；重置时不能与旧密码相同 |
| confirmPassword | 必须与 password 一致 |
| nickname | 1-50 位 |
| role | `user` / `admin`，未知值按 `user` 处理（最小权限） |

登录相关：账号优先按 `username` 匹配，未命中再按 `phone` 匹配；账号不存在与密码错误统一提示
「账号或密码错误」，避免账号枚举；`status=0` 的账号拒绝登录。

鉴权三道关卡（见 `AuthServiceImpl#requireLoginUser`）：是否已登出 → 用户是否存在/是否禁用
→ token 里的密码版本号是否与数据库一致。

### 3.11 时光档案接口（`ArchiveController` → `/api/archives`）

「时光代理人」核心业务，每位用户可记录属于自己的时光档案（一段回忆 / 一封信 / 一个约定），可选择公开到档案墙。

| # | 接口 | 鉴权 | 说明 |
| --- | --- | --- | --- |
| 1 | `GET /api/archives?page=1&size=10` | 登录 | 我的档案列表（按更新时间倒序） |
| 2 | `GET /api/archives/{id}` | 登录 | 档案详情（只能看自己的，或别人公开的） |
| 3 | `POST /api/archives` | 登录 | 新建档案（body 见 `ArchiveDTO`：title/content/archiveDate/tag/visibility） |
| 4 | `PUT /api/archives/{id}` | 登录 | 编辑档案（只能改自己的） |
| 5 | `DELETE /api/archives/{id}` | 登录 | 删除档案（只能删自己的） |
| 6 | `GET /api/archives/public?page=1` | 无需 | 公开档案墙（visibility=1，带作者用户名） |
| 7 | `GET /api/archives/search?q=关键字` | 登录 | 搜索我的档案（标题/内容/标签/日期） |
| 8 | `GET /api/archives/public/search?q=关键字` | 无需 | 搜索公开档案墙（跨所有用户，带作者名） |

`archiveDate` 格式为 `yyyy-MM-dd`；`visibility` 为 `1` 公开 / `0` 仅自己。

### 3.12 管理后台接口（`AdminUserController` / `AdminArchiveController`，仅 ADMIN）

所有接口都要求管理员角色（基于 `lc_user.permission=0` 判断），从 `Authorization: Bearer xxx` 头解析。
**管理员不能对自己执行：禁用、删除、角色降级**（避免把自己锁在门外）。

#### 用户管理 `/api/admin`

| # | 接口 | 方法 | 说明 |
| --- | --- | --- | --- |
| 1 | `/api/admin/stats` | GET | 统计概览：总用户数 / 正常 / 禁用 / 管理员数 / 今日新增 |
| 2 | `/api/admin/users?keyword=&status=&page=1&size=10` | GET | 用户列表（分页 + 关键词匹配 用户名/昵称/手机号 + 状态过滤，密码不返回） |
| 3 | `/api/admin/users/{id}/status` | PUT | 启用/禁用（`{status:0\|1}`，禁用会吊销该用户全部刷新令牌） |
| 4 | `/api/admin/users/{id}/role` | PUT | 角色调整（`{role:"user"\|"admin"}`，同步 `permission`） |
| 5 | `/api/admin/users/{id}/password` | PUT | 重置密码（`{password}`，6-20 位；成功后该用户所有旧 token 立即失效） |
| 6 | `/api/admin/users/{id}` | DELETE | 删除用户（连带吊销刷新令牌） |

#### 档案管理 `/api/admin/archives`

| # | 接口 | 方法 | 说明 |
| --- | --- | --- | --- |
| 1 | `/api/admin/archives/stats` | GET | 档案统计：总数 / 公开数 / 私密数 / 今日新增 |
| 2 | `/api/admin/archives?keyword=&visibility=&page=1&size=10` | GET | 跨所有用户的档案列表（JOIN 出所属用户名，支持关键词 + 可见性过滤） |
| 3 | `/api/admin/archives/{id}` | GET | 档案详情 |
| 4 | `/api/admin/archives/{id}` | PUT | 编辑档案（body 同 `ArchiveDTO`） |
| 5 | `/api/admin/archives/{id}` | DELETE | 删除档案 |

---

## 4. 管理后台页面

配套静态管理后台页面：**`src/main/resources/static/admin/index.html`**（登录页 + 统计卡片 + 用户管理 + 档案管理 标签页）。

Spring Boot 把 `static/` 下的文件直接映射到根路径，所以访问地址是：

```
http://localhost:8081/admin/index.html
```

**前置条件**

- 后端已在 dev 环境（端口 8081）启动；
- 用**管理员账号**登录（需要 `lc_user.role='admin'` 且 `permission=0`）。
  预置的演示账号 `lc_demo` 是普通用户，进不了后台。

**如果库里还没有管理员**，直接改库即可（改完已登录用户下次请求即生效，无需重登）：

```sql
UPDATE lc_user SET role = 'admin', permission = 0 WHERE username = 'lc_demo';
```

页面交互（同源，无需额外跨域配置）：登录 → 看统计概览 → 在「用户管理」标签页启用/禁用/调角色/重置密码/删除 → 在「档案管理」标签页查看/编辑/删除任意用户的档案。

---

## 5. 代码结构

```
src/main/java/com/fenglin/springboottest/
├── common/       R（统一返回）、BusinessException、GlobalExceptionHandler、
│                 TokenBlacklist（登出黑名单）、SmsCodeCleaner（过期验证码清理）、
│                 RefreshTokenCleaner（过期刷新令牌清理）
├── config/       MybatisPlusConfig（Mapper 扫描 + 分页）、PasswordEncoderConfig（BCrypt）
├── controller/
│   ├── AuthController        /api/auth/*           账号鉴权
│   ├── ArchiveController     /api/archives/*       时光档案（用户侧）
│   ├── AdminUserController   /api/admin/*          后台·用户管理
│   ├── AdminArchiveController /api/admin/archives/* 后台·档案管理
│   └── DemoController        演示接口（含权限分级示例）
├── entity/       User(lc_user)、SmsCode(lc_sms_code)、Archive(lc_archive)、RefreshToken(lc_refresh_token)
├── enums/        UserRole（user / admin，角色判断的唯一来源）
├── mapper/       UserMapper、SmsCodeMapper、ArchiveMapper、RefreshTokenMapper
├── dto/          RegisterDTO、LoginDTO、ResetPasswordDTO、UpdateProfileDTO、
│                 ChangePasswordDTO、ArchiveDTO（参数校验注解）
├── service/      AuthService + impl/AuthServiceImpl（验证码、注册、登录、重置密码业务逻辑）、
│                 CaptchaService + impl/CaptchaServiceImpl（图形验证码）
├── util/         JwtUtil（签发/解析 JWT）、OpaqueTokenUtil
└── UserController.java  早期练手用的 MVC 页面跳转（/user/*，与核心业务无关，可忽略）
src/main/resources/
├── static/
│   ├── index.html            首页/演示页
│   ├── archives/index.html   时光档案前端页
│   └── admin/index.html      管理后台前端页（登录 + 统计 + 用户管理 + 档案管理）
├── templates/user/login.html 早期练手模板
└── application*.properties   dev(8081) / prob / test 多环境配置
```

---

## 6. 本地启动

```bash
# 编译
mvn clean compile
# 启动（dev 环境，端口 8081）
mvn spring-boot:run
# 或者直接跑 jar
mvn package -DskipTests
java -jar target/springBootTest-0.0.1-SNAPSHOT.jar
```

数据源与相关开关在 `src/main/resources/application.properties`（dev 端口在 `application-dev.properties`）：

```properties
spring.datasource.url=jdbc:mysql://127.0.0.1:3306/link_click_auth?...
spring.datasource.username=root
spring.datasource.password=123456
auth.sms.debug=true          # 演示模式：把验证码返回给前端
jwt.secret=LinkClickAuthLocalDevSecretKey_时光代理人_2026
jwt.expire-seconds=604800
```

---

## 7. 前端联调

前端项目位于 **`D:\workSpace\JAVA\link-click-auth-vue`**（Vue 3 + Vite），`vite.config.js` 已配置代理，`/api` 转发到 `http://localhost:8081`：

```js
server: { port: 5173, proxy: { '/api': { target: 'http://localhost:8081', changeOrigin: true } } }
```

启动前端：

```bash
cd D:\workSpace\JAVA\link-click-auth-vue
npm install
npm run dev
```

打开 http://localhost:5173 → 切到「注册」页：填信息 → 点「获取验证码」（toast 中会显示演示验证码）→ 提交，成功后自动切回登录页。

登录页点「忘记密码？」会切到找回密码面板：填注册手机号 → 点「获取验证码」（toast 显示演示验证码）→ 填新密码 → 提交，
成功后自动回到登录面板，用新密码登录即可。

库里已预置一个演示账号，可直接登录页验证：

| 用户名 | 手机号 | 密码 |
| --- | --- | --- |
| lc_demo | 13611112222 | timepass |

登录成功后卡片底部会显示「已登录：lc_demo」和角色徽章，旁边入口：

- **个人中心**：改昵称、改密码。改密码需要输入当前密码，成功后会自动退出登录态，需要重新登录
- **时光档案**（普通用户可见）：新建 / 编辑 / 删除自己的档案，或浏览公开档案墙
- **管理后台**（仅管理员可见）：登录后访问 `http://localhost:8081/admin/index.html`，做用户与档案的全局管理
- **退出**：先调登出接口让 token 失效，再清本地凭证

---

## 8. 已知问题

### 8.1 密码是明文存储 / 明文比对（高危）

`AuthServiceImpl` 的注册、登录、改密、重置密码**都没有调用 `BCryptPasswordEncoder`**，而是直接：

- `register`：`user.setPassword(password)`（明文入库）
- `login`：`password.equals(user.getPassword())`（明文比对）
- `changePassword` / `resetPassword`：同样明文

项目里虽然定义了 `PasswordEncoderConfig` 的 `BCryptPasswordEncoder` Bean，但鉴权流程从未注入使用。**生产环境必须改为 BCrypt（或更强）哈希**，否则数据库一旦泄露，所有账号密码直接曝光。

> 当前开发库里已手动把一个管理员账号（`admin`）的密码以明文 `admin123` 写入，仅用于本地联调；正式使用前请改回哈希存储。

### 8.2 演示账号 `lc_demo` 在本库不存在

README 第 7 节提到的预置演示账号 `lc_demo / 13611112222 / timepass` 是基于早期脚本的示例，**当前 `link_click_auth` 库里并没有这条记录**（现有用户是 `admin` 与 `xx`，且手机号均为 NULL）。需要演示时自行注册，或按 8.1 的方式手动插入一条哈希密码的账号。
