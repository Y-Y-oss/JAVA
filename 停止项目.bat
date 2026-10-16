@echo off
rem ============================================================
rem  时光代理人 Link Click - 一键停止
rem  关闭占用 后端8081 / 前端5173 端口的进程
rem  自动化执行用  停止项目.bat nopause
rem ============================================================
setlocal
cd /d "%~dp0"
echo 停止 Link Click 后端8081 / 前端5173 ...
for %%p in (8081 5173) do (
  for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%%p " ^| findstr LISTENING') do (
    echo   端口 %%p  PID=%%a  关闭中
    taskkill /PID %%a /F >nul 2>&1
  )
)
echo 完成
if not "%~1"=="nopause" pause
endlocal
