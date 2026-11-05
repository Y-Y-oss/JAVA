@echo off
chcp 936 >nul 2>&1
title LinkClick-Backend (8081)
setlocal
cd /d "%~dp0..\springBootTest"

echo ============================================================
echo    后端 Spring Boot - 端口 8081
echo    首次启动需要编译，约 1-3 分钟，请耐心等待
echo    启动成功后【不要关闭本窗口】
echo ============================================================
echo.

if not defined MVN_CMD set "MVN_CMD=%~dp0..\springBootTest\mvnw.cmd"

call "%MVN_CMD%" spring-boot:run
set "RC=%errorlevel%"

echo.
echo ------------------------------------------------------------
echo [后端进程已退出] 退出码 = %RC%
if not "%RC%"=="0" echo [错误] 后端启动失败，请把上面的报错内容发给 AI 排查
echo ------------------------------------------------------------
pause
endlocal
