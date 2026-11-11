@echo off
title GameWizad - Auto Test & Verify (Phase 20 Verification)
echo ===================================================================
echo   GAMEWIZAD - AUTOMATED TEST & VERIFICATION SUITE (PHASE 20)
echo   Testing 4 Core Tests:
echo     1. Bot Red HP Bar (#E61E2A) & Lagging Catch-up Bar
echo     2. Stylized Crescent Slash ArrayMesh & 3-Tier Shader
echo     3. All 6 Hero Knight Skill VFX Overhauls
echo     4. Strict Zero Primitive Meshes Audit (0%% PrimitiveMesh)
echo ===================================================================
echo.
"D:\GameEngines\Godot\Godot_v4.3-stable_win64_console.exe" --headless --path "%~dp0src_game" -s "tests/test_phase_20_ultimate_slash_vfx_and_red_hp.gd"
echo.
echo ===================================================================
pause
