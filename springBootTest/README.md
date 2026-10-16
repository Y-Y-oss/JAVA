# 时光代理人 · 注册功能后端（springBootTest）

对应前端项目：`C:\Users\Administrator\Desktop\JAVA-main\时光代理人\link-click-auth-vue`

## 1. 技术栈

| 组件 | 版本 / 说明 |
| --- | --- |
| Spring Boot | 3.4.5（Java 17） |
| 数据库 | MySQL 8.x |
| 数据库层 | MyBatis-Plus 3.5.5（`mybatis-plus-spring-boot3-starter`） |
| 连接池 | HikariCP |
| 参数校验 | spring-boot-starter-validation |
| 密码加密 | spring-security-crypto（BCrypt，强度 10） |

## 2. 建库建表

脚本以文本形式保存在项目内：**`sql/link_click_auth.sql`**（可重复执行）。

```bash
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -uroot -p123456 < sql\link_click_auth.sql
```

或者：

```sql
mysql -uroot -p123456
mysql> source D:/workSpace/springBootTest/sql/link_click_auth.sql;
```

- 数据库：`link_click_auth`（utf8mb4）
- 表 `lc_user`：用户表，`username`、`phone` 各自唯一，密码存 BCrypt 哈希
- 表 `lc_sms_code`：短信验证码，`expire_time` 控制有效期，`consumed` 标记是否已使用

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
| password | 6-20 位，BCrypt 加密入库；重置时不能与旧密码相同 |
| confirmPassword | 必须与 password 一致 |
| nickname | 1-50 位 |
| role | `user` / `admin`，未知值按 `user` 处理（最小权限） |

登录相关：账号优先按 `username` 匹配，未命中再按 `phone` 匹配；账号不存在与密码错误统一提示
「账号或密码错误」，避免账号枚举；`status=0` 的账号拒绝登录。

鉴权三道关卡（见 `AuthServiceImpl#requireLoginUser`）：是否已登出 → 用户是否存在/是否禁用
→ token 里的密码版本号是否与数据库一致。

### 3.11 过期验证码清理

`common/SmsCodeCleaner` 每天凌晨 3:20 执行一次，删除 `expire_time` 早于「当前时间 - 
`auth.sms.cleanup-retention-hours`（默认 24 小时）」的记录。验证码本身 5 分钟就过期，
清理给得比它宽裕得多，不会影响任何正在进行的校验。

## 4. 代码结构

```
src/main/java/com/fenglin/springboottest/
├── common/       R（统一返回）、BusinessException、GlobalExceptionHandler、
│                 TokenBlacklist（登出黑名单）、SmsCodeCleaner（过期验证码清理）
├── config/       MybatisPlusConfig（Mapper 扫描 + 分页）、PasswordEncoderConfig（BCrypt）
├── controller/   AuthController      /api/auth/*
├── entity/       User(lc_user)、SmsCode(lc_sms_code)
├── enums/        UserRole（user / admin，角色判断的唯一来源）
├── mapper/       UserMapper、SmsCodeMapper
├── dto/          RegisterDTO、LoginDTO、ResetPasswordDTO、UpdateProfileDTO、ChangePasswordDTO（参数校验注解）
├── service/      AuthService + impl/AuthServiceImpl（验证码、注册、登录、重置密码业务逻辑）
└── util/         JwtUtil（签发 / 解析 JWT）
```

## 5. 本地启动

```bash
# 编译
mvn clean compile
# 启动（dev 环境，端口 8081）
mvn spring-boot:run
# 或者直接跑 jar
mvn package -DskipTests
java -jar target/springBootTest-0.0.1-SNAPSHOT.jar
```

数据源与相关开关在 `src/main/resources/application.properties`：

```properties
spring.datasource.url=jdbc:mysql://127.0.0.1:3306/link_click_auth?...
spring.datasource.username=root
spring.datasource.password=123456
auth.sms.debug=true          # 演示模式：把验证码返回给前端
```

## 6. 前端联调

前端 `vite.config.js` 已配置代理，`/api` 转发到 `http://localhost:8081`：

```js
server: { port: 5173, proxy: { '/api': { target: 'http://localhost:8081', changeOrigin: true } } }
```

启动前端：

```bash
cd C:\Users\Administrator\Desktop\JAVA-main\时光代理人\link-click-auth-vue
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
- **时光档案**（仅管理员可见）：点开后可以对比「公开档案」和「全部档案」两个接口，
  用普通账号点后者会看到 403 权限不足
- **退出**：先调登出接口让 token 失效，再清本地凭证
