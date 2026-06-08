# Runs on fakoli-dark (native Windows PowerShell). Collects GPU + Docker (SGLang/gaming) state
# with native tools (reliable, unlike WSL interop) and pushes it to the Mac via `wsl rsync`,
# where collect-metrics.sh / the dashboard consume it. No elevation required.
# Schedule via Task Scheduler for a live dashboard, or run on demand. To avoid a console
# window flashing every run, the scheduled task launches push-host-metrics.vbs (hidden), which
# runs this script with window style 0 — NOT powershell.exe directly.
$ErrorActionPreference = "SilentlyContinue"
function JNum($v){ if ($v -match '^\d+(\.\d+)?$') { $v } else { "null" } }

$name="unknown"; $used="null"; $total="null"; $util="null"
$gpuLine = (& nvidia-smi --query-gpu=name,memory.used,memory.total,utilization.gpu --format=csv,noheader,nounits 2>$null | Select-Object -First 1)
if ($gpuLine) { $p = $gpuLine -split '\s*,\s*'; $name=$p[0]; $used=(JNum $p[1]); $total=(JNum $p[2]); $util=(JNum $p[3]) }

$sg = (& docker ps --filter name=sglang --format "{{.Names}}" 2>$null | Select-Object -First 1)
$gaming = if ($sg) { "false" } else { "true" }
if (-not $sg) { $sg = "none" }

$ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$json = '{"host":"fakoli-dark","ts":"'+$ts+'","gpu":{"name":"'+$name+'","vram_used_mb":'+$used+',"vram_total_mb":'+$total+',"util_pct":'+$util+'},"sglang_container":"'+$sg+'","gaming_on":'+$gaming+'}'
Set-Content -Path "C:\Users\sdoum\fakoli-host-metrics.json" -Value $json -Encoding ascii
wsl -d Ubuntu-24.04 -- rsync -tz /mnt/c/Users/sdoum/fakoli-host-metrics.json mac:fakoli-runner/host-metrics.json 2>$null
Write-Output $json
