# 生成 DailyList 应用图标：橙红渐变底 + 白色圆环对勾
# 输出: App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png
Add-Type -AssemblyName System.Drawing

$size = 1024
$outPath = Join-Path $PSScriptRoot "..\App\Resources\Assets.xcassets\AppIcon.appiconset\AppIcon1024.png"

$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

# 背景渐变
$rect = New-Object System.Drawing.Rectangle(0, 0, $size, $size)
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    $rect,
    [System.Drawing.Color]::FromArgb(255, 255, 130, 95),
    [System.Drawing.Color]::FromArgb(255, 245, 55, 115),
    45)
$g.FillRectangle($bg, $rect)

# 白色圆环
$ringPen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 42)
$ringPen.Alignment = [System.Drawing.Drawing2D.PenAlignment]::Center
$g.DrawEllipse($ringPen, 252, 252, 520, 520)

# 对勾（两段圆头线）
$checkPen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 52)
$checkPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
$checkPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
$checkPen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
$g.DrawLine($checkPen, 350, 535, 465, 655)
$g.DrawLine($checkPen, 465, 655, 690, 400)

$g.Dispose()
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host "Icon saved to: $outPath"
