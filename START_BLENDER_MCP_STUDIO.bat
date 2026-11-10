@echo off
title Blender 4.2 LTS + Blender MCP Studio (GameWizad Pipeline)
echo ===================================================================
echo   BLENDER 4.2 LTS + BLENDER MCP STUDIO - 3D ASSET PIPELINE
echo   Bridge: Antigravity IDE ^<---^> Blender MCP (Port 9876) ^<---^> Godot 4
echo ===================================================================
echo.
echo Dang khoi dong Blender 4.2 LTS va kich hoat MCP Socket Server...
echo.

set BLENDER_BIN=D:\GameEngines\Blender\blender.exe
set SCRIPT_PATH=%~dp0src_game\tools\start_blender_mcp_gui.py

if not exist "%BLENDER_BIN%" (
    echo [LOI] Khong tim thay Blender tai: %BLENDER_BIN%
    pause
    exit /b 1
)

start "" "%BLENDER_BIN%" --python "%SCRIPT_PATH%"
echo [THANH CONG] Da mo Blender 4.2 LTS Studio va tu dong bat Server MCP!
exit /b 0
