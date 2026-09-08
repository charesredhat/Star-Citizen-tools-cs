Add-Type @"
using System;
using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential)]
public struct JOYINFOEX {
  public uint dwSize, dwFlags;
  public uint dwXpos, dwYpos, dwZpos, dwRpos, dwUpos, dwVpos;
  public uint dwButtons, dwButtonNumber, dwPOV, dwReserved1, dwReserved2;
}
public class JoyP {
  [DllImport("winmm.dll")] public static extern uint joyGetPosEx(uint id, ref JOYINFOEX pji);
}
"@

$out = "$PSScriptRoot\axis-result.txt"
$names = @("X","Y","Z","R","U","V")
$sc    = @{ "X"="js1_x"; "Y"="js1_y"; "Z"="js1_z"; "R"="js1_rotz"; "U"="js1_slider1"; "V"="js1_slider2" }

$min = @{}; $max = @{}
foreach ($n in $names) { $min[$n] = [uint32]::MaxValue; $max[$n] = [uint32]0 }
$btns = New-Object 'System.Collections.Generic.HashSet[int]'
$povs = New-Object 'System.Collections.Generic.HashSet[uint32]'

Write-Host ""
Write-Host "  T.FLIGHT HOTAS ONE - AXIS AND BUTTON DISCOVERY" -ForegroundColor Cyan
Write-Host "  ============================================================"
Write-Host ""

# Star Citizen takes the device exclusively; the legacy API then returns
# a synthetic dead-centre value for every axis and the capture is useless.
$sc_proc = Get-Process -Name StarCitizen -ErrorAction SilentlyContinue
if ($sc_proc) {
  Write-Host "  STOP - Star Citizen is still running (PID $($sc_proc.Id))." -ForegroundColor Red
  Write-Host "  It holds the joystick exclusively, so every axis will read as"
  Write-Host "  centred and this capture will tell us nothing."
  Write-Host ""
  Write-Host "  Close the game completely, then run this again." -ForegroundColor Yellow
  Write-Host ""
  exit 1
}

Write-Host "  Over the next 30 seconds, please do ALL of this:" -ForegroundColor Yellow
Write-Host ""
Write-Host "    1. Push the THROTTLE LEVER fully forward, then fully back."
Write-Host "    2. Push the RUDDER ROCKER fully left, then fully right."
Write-Host "    3. Move the STICK fully left/right and fully forward/back."
Write-Host "    4. Press EVERY button once, and push the HAT all 4 ways."
Write-Host ""
Write-Host "  Put your hands on the stick now." -ForegroundColor Green
foreach ($n in 5,4,3,2,1) { Write-Host "    starting in $n..." ; Start-Sleep -Seconds 1 }
Write-Host "  GO - work every control now." -ForegroundColor Green
$lastShown = -1

$p = New-Object JOYINFOEX
$p.dwSize  = [System.Runtime.InteropServices.Marshal]::SizeOf($p)
$p.dwFlags = 0xff

$end = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $end) {
  if ([JoyP]::joyGetPosEx(0, [ref]$p) -eq 0) {
    $vals = @($p.dwXpos, $p.dwYpos, $p.dwZpos, $p.dwRpos, $p.dwUpos, $p.dwVpos)
    for ($i = 0; $i -lt 6; $i++) {
      $n = $names[$i]; $v = $vals[$i]
      if ($v -lt $min[$n]) { $min[$n] = $v }
      if ($v -gt $max[$n]) { $max[$n] = $v }
    }
    for ($b = 0; $b -lt 32; $b++) { if ($p.dwButtons -band ([uint32]1 -shl $b)) { [void]$btns.Add($b + 1) } }
    if ($p.dwPOV -ne 65535) { [void]$povs.Add($p.dwPOV) }
  }
  $left = [int]((($end) - (Get-Date)).TotalSeconds)
  if ($left -ne $lastShown) {
    $found = @($names | Where-Object { ([int]$max[$_] - [int]$min[$_]) -gt 20000 })
    Write-Host ("  {0,2}s left   axes seen: {1}" -f $left, $(if ($found) { $found -join "," } else { "none yet" }))
    $lastShown = $left
  }
  Start-Sleep -Milliseconds 20
}
Write-Host "`r  Capture complete.              "

$lines = @()
$lines += "AXIS TRAVEL (winmm id 0 = T.Flight Hotas One)"
$lines += "============================================="
foreach ($n in $names) {
  $travel = [int]$max[$n] - [int]$min[$n]
  $verdict = if ($travel -gt 20000) { "MOVED  <-- real axis" } elseif ($travel -gt 2000) { "slight" } else { "static (phantom)" }
  $lines += ("{0}  ->  {1,-12}  min={2,-6} max={3,-6} travel={4,-6} {5}" -f $n, $sc[$n], $min[$n], $max[$n], $travel, $verdict)
}
$lines += ""
$lines += "BUTTONS PRESSED : " + (($btns | Sort-Object) -join ", ")
$lines += "HAT POV VALUES  : " + (($povs | Sort-Object) -join ", ") + "   (0=up 9000=right 18000=down 27000=left)"

$moved = @($names | Where-Object { ([int]$max[$_] - [int]$min[$_]) -gt 20000 })
if ($moved.Count -eq 0) {
  $lines += ""
  $lines += "WARNING: nothing moved. Either the controls were not worked during"
  $lines += "the capture, or something still holds the device exclusively."
}

$lines | Set-Content -Path $out -Encoding utf8
Write-Host ""
$lines | ForEach-Object { Write-Host "  $_" }
Write-Host ""
if ($moved.Count -gt 0) {
  Write-Host "  Real axes found: $($moved -join ', ')" -ForegroundColor Green
} else {
  Write-Host "  No axis movement detected - see warning above." -ForegroundColor Red
}
Write-Host "  Saved to $out" -ForegroundColor Green
