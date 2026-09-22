@echo off
setlocal
cd /d "%~dp0"
if not exist ".env" (
  echo .env bulunamadi. Once .env.example dosyasini .env olarak kopyalayip doldurun.
  pause
  exit /b 1
)
if not exist "node_modules" (
  echo Bagimliliklar kuruluyor...
  call npm install
  if errorlevel 1 exit /b 1
)
call npm start
