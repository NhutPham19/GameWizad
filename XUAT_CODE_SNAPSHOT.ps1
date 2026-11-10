# Script xuat Snapshot Code toan bo ma nguon GameWizad vao docs/CURRENT_CODE_SNAPSHOT.md
$outputFile = "docs/CURRENT_CODE_SNAPSHOT.md"
$srcDir = "src_game"

if (!(Test-Path "docs")) {
    New-Item -ItemType Directory -Path "docs" -Force | Out-Null
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# 📦 GAMEWIZAD - CURRENT CODE SNAPSHOT")
[void]$sb.AppendLine("Thời gian xuất: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$sb.AppendLine("Môi trường: Godot Engine 4.3+ | Renderer: Forward+ (NVIDIA RTX 4060)")
[void]$sb.AppendLine("Kiến trúc: 100% KayKit GLB/GLTF - Zero Primitive Geometry (0% Hình Khối Cơ Bản)")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")

$files = Get-ChildItem -Path $srcDir -Recurse -File | 
         Where-Object { 
             ($_.Extension -in @(".gd", ".gdshader", ".tscn")) -and 
             ($_.FullName -notmatch "\\.godot\\") 
         } |
         Sort-Object FullName

Write-Host "Dang thu thap $($files.Count) tep ma nguon..."

$tick3 = [string][char]96 + [string][char]96 + [string][char]96

foreach ($file in $files) {
    $relPath = $file.FullName.Substring((Get-Item .).FullName.Length + 1).Replace("\", "/")
    [void]$sb.AppendLine("## 📄 File: " + $relPath)
    
    $ext = $file.Extension.ToLower()
    $lang = "text"
    if ($ext -eq ".gd") { $lang = "gdscript" }
    elseif ($ext -eq ".gdshader") { $lang = "glsl" }
    elseif ($ext -eq ".tscn") { $lang = "ini" }
    
    [void]$sb.AppendLine($tick3 + $lang)
    $content = [System.IO.File]::ReadAllText($file.FullName, [System.Text.Encoding]::UTF8)
    [void]$sb.AppendLine($content)
    [void]$sb.AppendLine($tick3)
    [void]$sb.AppendLine("")
}

[System.IO.File]::WriteAllText($outputFile, $sb.ToString(), [System.Text.Encoding]::UTF8)
$len = (Get-Item $outputFile).Length
$fileSizeMB = [math]::Round($len / 1MB, 2)
Write-Host "Xuat thanh cong $outputFile ($fileSizeMB MB, $($files.Count) files)!"
