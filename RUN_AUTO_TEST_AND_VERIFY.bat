@echo off
title GameWizad - Auto Test & Verify (Phase 17 Verification)
echo ===================================================================
echo   GAMEWIZAD - AUTOMATED TEST & VERIFICATION SUITE
echo   Testing 4 Core Tests:
echo     1. Auto Stair Climbing (Hero & Minion Running_A)
echo     2. LMB Normal Attack Deals Damage (-25 HP, Overhead HP bar)
echo     3. Map Perimeter Boundary Protection (No falling off)
echo     4. Zero Primitive Geometry Check (0%% primitive meshes)
echo ===================================================================
echo.
"D:\GameEngines\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "%~dp0src_game" -s "tests/test_phase_17_full_verification.gd"
echo.
echo ===================================================================
pause
