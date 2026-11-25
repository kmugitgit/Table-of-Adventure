Add-Type -AssemblyName System.Drawing
$root = $PSScriptRoot
$items = Get-Content (Join-Path $root 'sources.json') -Raw | ConvertFrom-Json
$pngDir = Join-Path $root 'png'
New-Item -ItemType Directory -Force -Path $pngDir | Out-Null
$sheet = [System.Drawing.Bitmap]::new(800, 640)
$sg = [System.Drawing.Graphics]::FromImage($sheet)
$sg.Clear([System.Drawing.Color]::FromArgb(255,48,55,65))
$sg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$sg.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$font = [System.Drawing.Font]::new('Consolas',10)
$index = 0
foreach ($item in $items) {
  $src = [System.Drawing.Bitmap]::new($item.path)
  $left=$src.Width; $top=$src.Height; $right=0; $bottom=0
  for ($y=0; $y -lt $src.Height; $y++) {
    for ($x=0; $x -lt $src.Width; $x++) {
      if ($src.GetPixel($x,$y).A -ge 128) {
        $left=[Math]::Min($left,$x); $top=[Math]::Min($top,$y)
        $right=[Math]::Max($right,$x); $bottom=[Math]::Max($bottom,$y)
      }
    }
  }
  $w=$right-$left+1; $h=$bottom-$top+1
  $scale=[Math]::Min(30.0/$w,30.0/$h)
  $dw=[Math]::Max(1,[int][Math]::Round($w*$scale))
  $dh=[Math]::Max(1,[int][Math]::Round($h*$scale))
  $ox=[int][Math]::Floor((32-$dw)/2); $oy=[int][Math]::Floor((32-$dh)/2)
  $dst=[System.Drawing.Bitmap]::new(32,32)
  for ($y=0; $y -lt $dh; $y++) {
    for ($x=0; $x -lt $dw; $x++) {
      $sx=$left+[Math]::Min($w-1,[int][Math]::Floor(($x+0.5)*$w/$dw))
      $sy=$top+[Math]::Min($h-1,[int][Math]::Floor(($y+0.5)*$h/$dh))
      $c=$src.GetPixel($sx,$sy)
      if ($c.A -ge 128) { $dst.SetPixel($ox+$x,$oy+$y,[System.Drawing.Color]::FromArgb(255,$c.R,$c.G,$c.B)) }
    }
  }
  $dst.Save((Join-Path $pngDir ($item.name+'.png')),[System.Drawing.Imaging.ImageFormat]::Png)
  $cx=($index%5)*160; $cy=[int][Math]::Floor($index/5)*128
  $sg.DrawImage($dst,[System.Drawing.Rectangle]::new($cx+32,$cy+4,96,96),0,0,32,32,[System.Drawing.GraphicsUnit]::Pixel)
  $sg.DrawString($item.name,$font,[System.Drawing.Brushes]::White,[single]($cx+3),[single]($cy+106))
  $index++; $src.Dispose(); $dst.Dispose()
}
$sheet.Save((Join-Path $root 'preview.png'),[System.Drawing.Imaging.ImageFormat]::Png)
$sg.Dispose(); $sheet.Dispose(); $font.Dispose()
Compress-Archive -Path (Join-Path $pngDir '*.png') -DestinationPath (Join-Path $root 'fish_sprites_32.zip') -Force
Write-Output "Saved $index sprites at 32x32"
