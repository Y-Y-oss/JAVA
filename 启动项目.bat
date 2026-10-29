@echo off
rem ============================================================
rem  时光代理人 Link Click - 一键启动
rem  用法:双击本文件;自动化执行用  启动项目.bat nopause
rem  说明:本机每次重置会删除 node_modules / target,
rem       本脚本会自动重装依赖;项目内路径全部用相对路径
rem ============================================================
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo.
echo ==========================================
echo    时光代理人 Link Click 一键启动
echo ==========================================
echo.

rem ---- 0. 清掉会顶掉后端端口的环境变量(WorkBuddy终端的坑) ----
set "SERVER__PORT="
set "SERVER_PORT="

rem ---- 1. 定位外部工具 mysql / maven:先 PATH,再用已知安装路径 ----
set "MYSQL_EXE="
for /f "delims=" %%i in ('where mysql 2^>nul') do if not defined MYSQL_EXE set "MYSQL_EXE=%%i"
if not defined MYSQL_EXE if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
if not defined MYSQL_EXE (
  echo [错误] 找不到 mysql 客户端,请确认已安装 MySQL 8
  goto fail
)

set "MVN_CMD="
for /f "delims=" %%i in ('where mvn 2^>nul') do if not defined MVN_CMD set "MVN_CMD=%%i"
if not defined MVN_CMD if exist "D:\IntelliJ IDEA 2024.3.2.2\plugins\maven\lib\maven3\bin\mvn.cmd" set "MVN_CMD=D:\IntelliJ IDEA 2024.3.2.2\plugins\maven\lib\maven3\bin\mvn.cmd"
if not defined MVN_CMD if exist "%~dp0springBootTest\mvnw.cmd" set "MVN_CMD=%~dp0springBootTest\mvnw.cmd"
if not defined MVN_CMD (
  echo [错误] 找不到 Maven,请安装 Maven 或保留 IDEA
  goto fail
)

rem ---- 2. MySQL 服务 ----
echo [1/5] 检查 MySQL 服务...
netstat -ano | findstr ":3306 " | findstr LISTENING >nul
if errorlevel 1 (
  echo        MySQL 未运行,尝试启动 MySQL80...
  net start MySQL80 >nul 2>&1
  if errorlevel 1 (
    echo [错误] MySQL 启动失败,可能需要管理员权限,请手动启动后重试
    goto fail
  )
)
echo        OK

rem ---- 3. 数据库 ----
echo [2/5] 检查数据库 link_click_auth...
"%MYSQL_EXE%" -uroot -p123456 -e "SELECT 1;" >nul 2>&1
if errorlevel 1 (
  echo [错误] 无法连接 MySQL,账号 root 密码 123456,请检查
  goto fail
)
"%MYSQL_EXE%" -uroot -p123456 -N -e "SHOW DATABASES LIKE 'link_click_auth';" 2>nul | findstr "link_click_auth" >nul
if errorlevel 1 (
  echo        数据库不存在,执行建库脚本 springBootTest\sql\link_click_auth.sql
  "%MYSQL_EXE%" -uroot -p123456 --default-character-set=utf8mb4 < "%~dp0springBootTest\sql\link_click_auth.sql" 2>nul
  if errorlevel 1 (
    echo [错误] 建库失败
    goto fail
  )
  echo        建库完成
) else (
  echo        已存在,跳过
)

rem ---- 4. 后端 8081 (若端口已被占用,先结束旧进程,确保每次都部署最新代码) ----
echo [3/5] 启动后端 Spring Boot (8081)...
for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr ":8081 " ^| findstr LISTENING') do (
  echo        8081 被 PID=%%a 占用,先结束旧进程以部署最新代码
  taskkill /F /PID %%a >nul 2>&1
)
timeout /t 2 >nul
echo        启动后端,新窗口 LinkClick-Backend
start "LinkClick-Backend" /D "%~dp0springBootTest" cmd /k call "%MVN_CMD%" -q spring-boot:run

rem ---- 5. 前端 5173 ----
echo [4/5] 检查前端端口 5173...
netstat -ano | findstr ":5173 " | findstr LISTENING >nul
if not errorlevel 1 (
  echo        前端已在运行,跳过
) else (
  if not exist "%~dp0link-click-auth-vue\node_modules" (
    echo        安装前端依赖 npm ci,约 1-2 分钟...
    pushd "%~dp0link-click-auth-vue"
    call npm ci --no-audit --no-fund --loglevel=error
    if errorlevel 1 (
      echo        npm ci 失败,改用 npm install...
      call npm install --no-audit --no-fund --loglevel=error
      if errorlevel 1 (
        echo [错误] 前端依赖安装失败
        popd
        goto fail
      )
    )
    popd
  )
  echo        启动前端 Vite,新窗口 LinkClick-Frontend
  start "LinkClick-Frontend" /D "%~dp0link-click-auth-vue" cmd /k npm run dev
)

rem ---- 6. 健康检查:等后端出验证码,最长约 120 秒 ----
echo [5/5] 等待后端就绪...
set "HC="
for /l %%n in (1,1,60) do (
  for /f %%c in ('curl -s -o nul -m 2 -w "%%{http_code}" "http://localhost:8081/api/auth/captcha" 2^>nul') do set "HC=%%c"
  if "!HC!"=="200" goto hc_done
  ping -n 2 127.0.0.1 >nul
)
:hc_done
if "!HC!"=="200" (
  echo        后端已就绪
) else (
  echo [警告] 后端 120 秒内未就绪,请到 LinkClick-Backend 窗口查看日志
)

echo.
echo ==========================================
echo    完成
echo    前端 http://localhost:5173  自动开浏览器
echo    后端 http://localhost:8081
echo    验证码答案在 springBootTest\log\xx.log
echo ==========================================
echo.
goto end

:fail
echo.
echo 启动失败,可按 AI助手启动指南.md 排查

:end
if not "%~1"=="nopause" pause
endlocal
