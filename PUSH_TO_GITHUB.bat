@echo off
chcp 65001 >nul
title DAY CODE GAMEWIZAD LEN GITHUB
cd /d "%~dp0"

echo ======================================================================
echo   DANG TIEN HANH DAY MA NGUON LEN GITHUB (NhutPham19/GameWizad)
echo ======================================================================
echo.

git status
echo.
echo Dang chay: git push origin main ...
git push origin main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ======================================================================
    echo   [THANH CONG 100%%] DA PUSH TOAN BO CODE LEN GITHUB THANH CONG!
    echo ======================================================================
    pause
    exit /b 0
)

echo.
echo ----------------------------------------------------------------------
echo Git Credential chua duoc cap quyen hoac Token cu da het han (401).
echo Ban co muon nhap Personal Access Token (PAT) moi de push luon khong?
echo (Tao token tai: https://github.com/settings/tokens co tich chon 'repo')
echo ----------------------------------------------------------------------
set /p USER_TOKEN="Dan Personal Access Token cua ban vao day (hoac an Enter de thoat): "

if "%USER_TOKEN%"=="" (
    exit /b 1
)

echo Dang push bang Token moi...
git push https://NhutPham19:%USER_TOKEN%@github.com/NhutPham19/GameWizad.git main

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ======================================================================
    echo   [THANH CONG 100%%] DA PUSH CODE LEN GITHUB VOI TOKEN MOI!
    echo ======================================================================
) else (
    echo.
    echo [LOI] Push that bai. Vui long kiem tra lai Token va quyen 'repo'.
)

pause
