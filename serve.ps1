# Local preview server for the Aarush Suzuki site (no Node/Python needed).
# Usage: powershell -ExecutionPolicy Bypass -File serve.ps1 [-Port 5180] [-Root site]
# If the port is already in use, the next free port is tried automatically.
param([int]$Port = 5180, [string]$Root = 'site')
$base = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = [IO.Path]::GetFullPath((Join-Path $base $Root))
$types = @{ '.html'='text/html; charset=utf-8'; '.css'='text/css'; '.js'='application/javascript'; '.json'='application/json';
  '.png'='image/png'; '.jpg'='image/jpeg'; '.jpeg'='image/jpeg'; '.webp'='image/webp'; '.svg'='image/svg+xml'; '.ico'='image/x-icon';
  '.woff2'='font/woff2'; '.woff'='font/woff'; '.ttf'='font/ttf'; '.otf'='font/otf'; '.xml'='application/xml'; '.txt'='text/plain'; '.mp4'='video/mp4'; '.webm'='video/webm' }

$listener = $null
for ($p = $Port; $p -lt $Port + 20; $p++) {
  $try = [System.Net.HttpListener]::new()
  $try.Prefixes.Add("http://localhost:$p/")
  try { $try.Start(); $listener = $try; $Port = $p; break } catch { $try.Close() }
}
if (-not $listener) { Write-Host "No free port found between $Port and $($Port + 19)."; exit 1 }
Write-Host ""
Write-Host "  Aarush Suzuki site is running:  http://localhost:$Port/" -ForegroundColor Green
Write-Host "  Serving folder: $root"
Write-Host "  Press Ctrl+C to stop."
Write-Host ""

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
  $file = [IO.Path]::GetFullPath((Join-Path $root $path))
  if (Test-Path $file -PathType Container) {
    if (-not $ctx.Request.Url.AbsolutePath.EndsWith('/')) {
      $ctx.Response.Redirect($ctx.Request.Url.AbsolutePath + '/' + $ctx.Request.Url.Query); $ctx.Response.Close(); continue
    }
    $file = Join-Path $file 'index.html'
  }
  if (-not $file.StartsWith($root) -or -not (Test-Path $file -PathType Leaf)) {
    $ctx.Response.StatusCode = 404
    $file = Join-Path $root '404.html'
  }
  if (Test-Path $file -PathType Leaf) {
    $bytes = [IO.File]::ReadAllBytes($file)
    $ext = [IO.Path]::GetExtension($file).ToLower()
    $ctx.Response.ContentType = if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' }
    # pages/CSS/JS always fresh while editing; images and fonts may be cached so pages don't wait on them
    $cache = if ($ext -match '^\.(html|css|js|json|xml|txt)$') { 'no-store, no-transform' } else { 'public, max-age=600' }
    $ctx.Response.Headers.Add('Cache-Control', $cache)
    $ctx.Response.Headers.Add('Accept-Ranges', 'bytes')
    # Byte ranges (needed by Safari / iOS to play video)
    $range = $ctx.Request.Headers['Range']
    if ($range -match '^bytes=(\d*)-(\d*)$' -and $ctx.Response.StatusCode -eq 200) {
      $len = $bytes.Length
      if ($Matches[1] -eq '') { $start = [Math]::Max(0, $len - [int64]$Matches[2]); $end = $len - 1 }
      else { $start = [int64]$Matches[1]; $end = if ($Matches[2]) { [Math]::Min([int64]$Matches[2], $len - 1) } else { [Math]::Min($start + 1048575, $len - 1) } }
      if ($start -ge $len) { $ctx.Response.StatusCode = 416; $ctx.Response.Headers.Add('Content-Range', "bytes */$len"); $ctx.Response.Close(); continue }
      $ctx.Response.StatusCode = 206
      $ctx.Response.Headers.Add('Content-Range', "bytes $start-$end/$len")
      $ctx.Response.ContentLength64 = $end - $start + 1
      try { $ctx.Response.OutputStream.Write($bytes, [int]$start, [int]($end - $start + 1)) } catch {}
    } else {
      try { $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length) } catch {}
    }
  }
  $ctx.Response.Close()
}
