@echo off
chcp 936 >nul 2>&1
title LinkClick-Frontend (5173)
setlocal
cd /d "%~dp0..\link-click-auth-vue"

echo ============================================================
echo    前端 Vite - 端口 5173
echo    启动成功后【不要关闭本窗口】
echo ============================================================
echo.

if not exist "node_modules" (
  echo [首次] 正在安装前端依赖 npm ci，约 1-2 分钟...
  call npm ci --no-audit --no-fund --loglevel=error
  if errorlevel 1 (
    echo [警告] npm ci 失败，改用 npm install 重试...
    call npm install --no-audit --no-fund --loglevel=error
  )
  if errorlevel 1 (
    echo [错误] 前端依赖安装失败，请检查网络或 node/npm 是否可用
    pause
    exit /b 1
  )
)

call npm run dev
set "RC=%errorlevel%"

echo.
echo ------------------------------------------------------------
echo [前端进程已退出] 退出码 = %RC%
if not "%RC%"=="0" echo [错误] 前端启动失败，请把上面的报错内容发给 AI 排查
echo ------------------------------------------------------------
pause
endlocal
