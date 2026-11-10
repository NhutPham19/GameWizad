@echo off
title GameWizad - KayKit Multi-Tier Arena (1 Hero Knight vs 5 Minions)
echo ===================================================================
echo   GAMEWIZAD (DIRECTIVE 16 - KAYKIT MULTI-TIER MASTER PLAN)
echo   Renderer: Godot 4.3 Forward+ Vulkan (NVIDIA GeForce RTX 4060)
echo   100%% KAYKIT GLB/GLTF - ZERO PRIMITIVE GEOMETRY (0%% HINH KHOI)
echo ===================================================================
echo.
echo Dang khoi dong GameWizad Multi-Tier Arena...
echo.
echo ===================================================================
echo  HE THONG DIEU KHIEN HERO KNIGHT 3D:
echo ===================================================================
echo   - [WASD]             : Di chuyen chuan isometric theo camera (W: Len, S: Xuong, A: Trai, D: Phai)
echo   - [Chuot Trai (LMB)] : Combo chem 3 nhip (Slice H -^> Slice D -^> Chop) + Vet kiem hat vang kim
echo   - [Chuot Phai (RMB)] : Do khien phan kich + Song xung kich Decal day lui quan dich
echo   - [Phim Q]           : Tuyet chieu xoay kiem 360 do + An chu lua Decal da tang (3.5m ban kinh)
echo   - [Phim E]           : Phong dan 3D that KayKit (smokebomb.gltf bay vong cung no khoi)
echo   - [Phim Space]       : Luot ne Dodge Forward (14 m/s)
echo   - [Phim C / F]       : Nhay cao vuot dia hinh (Jump Velocity 8.5 m/s)
echo ===================================================================
echo  MUC TIEU CHIEN DAU:
echo   - Tieu diet 5 Linh Barbarian (2 o Tang 1, 2 o Tang 2, 1 Thu Linh o Tang 3)
echo   - Theo doi bang do thong so StrictQAHUD (FPS, 0 Primitive Check, Active Bones)
echo ===================================================================
echo.
start "" "D:\GameEngines\Godot\Godot_v4.3-stable_win64.exe" --path "%~dp0src_game" --resolution 1600x900 "res://scenes/levels/kaykit_multitier_arena.tscn"
exit
