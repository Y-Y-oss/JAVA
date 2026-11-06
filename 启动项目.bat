@echo off
chcp 936 >nul 2>&1
title 时光代理人 Link Click - 一键启动
setlocal EnableDelayedExpansion
cd /d "%~dp0"
set "ROOT=%~dp0"

rem ============================================================
rem  时光代理人 Link Click - 一键启动
rem  用法：双击本文件
rem       启动项目.bat restart    强制重启后端（默认已在运行则跳过）
rem  排错：每一步都写入同目录「启动日志.txt」
rem ============================================================

set "LOG=%~dp0启动日志.txt"
echo [%date% %time%] 启动脚本开始 > "%LOG%"

call :log "=========================================="
call :log "    时光代理人 Link Click 一键启动"
call :log "=========================================="

rem ---- 0. 清掉可能顶掉后端端口的环境变量 ----
set "SERVER__PORT="
set "SERVER_PORT="
call :log "[0] 已清理 SERVER__PORT / SERVER_PORT"

rem ---- 1. 定位 mysql 客户端 ----
set "MYSQL_EXE="
for /f "delims=" %%i in ('where mysql 2^>nul') do if not defined MYSQL_EXE set "MYSQL_EXE=%%i"
if not defined MYSQL_EXE if exist "C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe" set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Server 8.4\bin\mysql.exe"
if not defined MYSQL_EXE if exist "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe"
if not defined MYSQL_EXE if exist "C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql.exe" set "MYSQL_EXE=C:\Program Files\MySQL\MySQL Server 5.7\bin\mysql.exe"
if not defined MYSQL_EXE (
  call :log "[错误] 找不到 mysql 客户端，请确认已安装 MySQL"
  goto fail
)
call :log "[1] mysql 客户端: %MYSQL_EXE%"

rem ---- 2. 定位 Maven ----
set "MVN_CMD="
for /f "delims=" %%i in ('where mvn 2^>nul') do if not defined MVN_CMD set "MVN_CMD=%%i"
if not defined MVN_CMD if exist "D:\IntelliJ IDEA 2024.3.2.2\plugins\maven\lib\maven3\bin\mvn.cmd" set "MVN_CMD=D:\IntelliJ IDEA 2024.3.2.2\plugins\maven\lib\maven3\bin\mvn.cmd"
if not defined MVN_CMD if exist "%ROOT%springBootTest\mvnw.cmd" set "MVN_CMD=%ROOT%springBootTest\mvnw.cmd"
if not defined MVN_CMD (
  call :log "[错误] 找不到 Maven（mvn / IDEA Maven / mvnw 均不可用）"
  goto fail
)
call :log "[2] Maven: %MVN_CMD%"

rem ---- 3. MySQL 服务 ----
call :log "[3] 检查 MySQL 服务..."
netstat -ano | findstr ":3306" | findstr "LISTENING" >nul
if not errorlevel 1 (
  call :log "      MySQL 已在运行"
  goto mysql_ok
)
call :log "      MySQL 未运行，尝试启动服务..."
set "MYSQL_SVC_OK="
for %%s in (MySQL84 MySQL80 MySQL57 MySQL) do (
  net start %%s >nul 2>&1
  if not errorlevel 1 set "MYSQL_SVC_OK=1" & call :log "      已启动服务 %%s"
)
if not defined MYSQL_SVC_OK (
  call :log "[错误] MySQL 启动失败，请右键「以管理员身份运行」本文件后重试"
  goto fail
)
:mysql_ok
call :log "[3] MySQL OK"

rem ---- 4. 数据库 ----
call :log "[4] 检查数据库 link_click_auth..."
"%MYSQL_EXE%" -uroot -p123456 -e "SELECT 1;" >nul 2>&1
if errorlevel 1 (
  call :log "[错误] 无法连接 MySQL（root / 123456），请检查密码"
  goto fail
)
"%MYSQL_EXE%" -uroot -p123456 -N -e "SHOW DATABASES LIKE 'link_click_auth';" 2>nul | findstr "link_click_auth" >nul
if errorlevel 1 (
  call :log "      数据库不存在，执行建库脚本..."
  "%MYSQL_EXE%" -uroot -p123456 --default-character-set=utf8mb4 < "%ROOT%springBootTest\sql\link_click_auth.sql" 2>nul
  if errorlevel 1 (
    call :log "[错误] 建库失败"
    goto fail
  )
  call :log "      建库完成"
) else (
  call :log "      数据库已存在，跳过（不会清空账号）"
)

rem ---- 5. 后端 8081 ----
call :log "[5] 检查后端 8081..."
set "BK_UP="
for /f %%c in ('curl -s -o nul -m 2 -w "%%{http_code}" "http://localhost:8081/api/auth/captcha" 2^>nul') do set "BK_UP=%%c"
if /i "%~1"=="restart" set "BK_UP="

if "!BK_UP!"=="200" (
  call :log "      后端已在运行，跳过（需要重启请用：启动项目.bat restart）"
  goto fe_start
)

for /f "tokens=5" %%a in ('netstat -ano 2^>nul ^| findstr ":8081" ^| findstr "LISTENING"') do (
  call :log "      8081 被 PID=%%a 占用，先结束旧进程"
  taskkill /F /PID %%a >nul 2>&1
)
call :log "      启动后端，新窗口 LinkClick-Backend（首次编译 1-3 分钟）"
start "LinkClick-Backend" /D "%ROOT%springBootTest" cmd /k "%ROOT%scripts\run-backend.bat"

:fe_start
rem ---- 6. 前端 5173 ----
call :log "[6] 检查前端 5173..."
netstat -ano | findstr ":5173" | findstr "LISTENING" >nul
if not errorlevel 1 (
  call :log "      前端已在运行，跳过"
  goto wait_backend
)
call :log "      启动前端，新窗口 LinkClick-Frontend"
start "LinkClick-Frontend" /D "%ROOT%link-click-auth-vue" cmd /k "%ROOT%scripts\run-frontend.bat"

:wait_backend
rem ---- 7. 等后端就绪（每秒一个点，不会再"静默卡住"）----
call :log "[7] 等待后端就绪..."
echo 正在等待后端就绪（每秒一个点，最长约 3 分钟）：
set "HC="
set "_n=0"
:hc_loop
set /a _n+=1
set "HC="
for /f %%c in ('curl -s -o nul -m 2 -w "%%{http_code}" "http://localhost:8081/api/auth/captcha" 2^>nul') do set "HC=%%c"
if "!HC!"=="200" goto hc_done
if !_n! geq 90 goto hc_timeout
<nul set /p "=."
ping -n 2 127.0.0.1 >nul
goto hc_loop

:hc_done
echo.
call :log "      后端已就绪（约 !_n! 秒）"
goto ready

:hc_timeout
echo.
call :log "[警告] 后端 180 秒内未就绪，请查看 LinkClick-Backend 窗口里的报错"
goto fail

:ready
call :log "=========================================="
call :log "完成：前端 http://192.168.68.14:5173"
call :log "      后端 http://192.168.68.14:8081"
call :log "验证码答案在 springBootTest\log\xx.log"
call :log "=========================================="
start "" "http://192.168.68.14:5173"
goto end

:fail
call :log "启动未完成，请参考 AI助手启动指南.md，详细过程见 启动日志.txt"

:end
call :log "脚本结束（窗口暂停，方便查看；关闭窗口不影响已启动的服务）"
if not "%~1"=="nopause" pause
endlocal
goto :eof

rem ---- 日志子程序 ----
:log
echo %~1
echo [%date% %time%] %~1 >> "%LOG%"
goto :eof
