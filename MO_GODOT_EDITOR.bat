@echo off
title Godot 4.3 Editor - GameWizad
echo =======================================================
echo   MO GODOT 4.3 EDITOR - DU AN GAMEWIZAD
echo =======================================================
echo.
echo Dang mo giao dien Godot Engine Editor...
echo Ban co the mo file: res://scenes/levels/main_arena.tscn
echo de xem toan bo Mesh 3D, Shaders va Viewport do hoa!
echo.
start "" "D:\GameEngines\Godot\Godot_v4.3-stable_win64.exe" --editor --path "%~dp0src_game"
exit
