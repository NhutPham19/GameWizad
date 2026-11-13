# Script export 25 file am thanh thuc te dang su dung
$destDir = "docs/AUDIO_EXPORT_FOR_ARGONS/audio_files"
if (!(Test-Path $destDir)) {
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
}

$files = @(
    "src_game/assets/audio/rpg/knifeSlice.ogg",
    "src_game/assets/audio/rpg/knifeSlice2.ogg",
    "src_game/assets/audio/rpg/chop.ogg",
    "src_game/assets/audio/rpg/drawKnife1.ogg",
    "src_game/assets/audio/rpg/drawKnife2.ogg",
    "src_game/assets/audio/rpg/drawKnife3.ogg",
    "src_game/assets/audio/rpg/cloth1.ogg",
    "src_game/assets/audio/rpg/cloth2.ogg",
    "src_game/assets/audio/rpg/footstep00.ogg",
    "src_game/assets/audio/rpg/footstep01.ogg",
    "src_game/assets/audio/rpg/footstep02.ogg",
    "src_game/assets/audio/impact/impactMetal_light_000.ogg",
    "src_game/assets/audio/impact/impactMetal_medium_000.ogg",
    "src_game/assets/audio/impact/impactMetal_medium_001.ogg",
    "src_game/assets/audio/impact/impactMetal_heavy_000.ogg",
    "src_game/assets/audio/impact/impactMetal_heavy_001.ogg",
    "src_game/assets/audio/impact/impactMetal_heavy_002.ogg",
    "src_game/assets/audio/impact/impactMetal_heavy_003.ogg",
    "src_game/assets/audio/impact/impactPlate_heavy_000.ogg",
    "src_game/assets/audio/impact/impactPunch_heavy_000.ogg",
    "src_game/assets/audio/impact/impactPunch_heavy_001.ogg",
    "src_game/assets/audio/impact/impactPunch_heavy_002.ogg",
    "src_game/assets/audio/impact/impactSoft_heavy_000.ogg",
    "src_game/assets/audio/scifi/lowFrequency_explosion_000.ogg",
    "src_game/assets/audio/scifi/lowFrequency_explosion_001.ogg"
)

$copied = 0
foreach ($f in $files) {
    if (Test-Path $f) {
        Copy-Item -Path $f -Destination $destDir -Force
        $copied++
    } else {
        Write-Warning "Khong tim thay: $f"
    }
}

Write-Output "DA XUAT THANH CONG $copied / $($files.Count) TEP AM THANH VAO $destDir!"
