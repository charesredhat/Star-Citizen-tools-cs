Add-Type @"
using System;
using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential)]
public struct JOYINFOEX {
  public uint dwSize, dwFlags;
  public uint dwXpos, dwYpos, dwZpos, dwRpos, dwUpos, dwVpos;
  public uint dwButtons, dwButtonNumber, dwPOV, dwReserved1, dwReserved2;
}
public class JoyM {
  [DllImport("winmm.dll")] public static extern uint joyGetPosEx(uint id, ref JOYINFOEX pji);
}
"@

$sc_proc = Get-Process -Name StarCitizen -ErrorAction SilentlyContinue
if ($sc_proc) {
  Write-Host "`n  STOP - close Star Citizen first (it locks the joystick).`n" -ForegroundColor Red
  exit 1
}

$names = @("X","Y","Z","R","U","V")
$sc    = @{ "X"="js1_x"; "Y"="js1_y"; "Z"="js1_z"; "R"="js1_rotz"; "U"="js1_slider1"; "V"="js1_slider2" }

function Read-Axes {
  $p = New-Object JOYINFOEX
  $p.dwSize = [System.Runtime.InteropServices.Marshal]::SizeOf($p)
  $p.dwFlags = 0xff
  $acc = @{}; foreach ($n in $names) { $acc[$n] = @() }
  for ($i = 0; $i -lt 12; $i++) {
    if ([JoyM]::joyGetPosEx(0, [ref]$p) -eq 0) {
      $v = @($p.dwXpos,$p.dwYpos,$p.dwZpos,$p.dwRpos,$p.dwUpos,$p.dwVpos)
      for ($j = 0; $j -lt 6; $j++) { $acc[$names[$j]] += [int]$v[$j] }
    }
    Start-Sleep -Milliseconds 25
  }
  $res = @{}
  foreach ($n in $names) {
    if ($acc[$n].Count -gt 0) { $res[$n] = [int](($acc[$n] | Measure-Object -Average).Average) }
    else { $res[$n] = -1 }
  }
  return $res
}

function Step-Capture($prompt) {
  Write-Host ""
  Write-Host "  >> $prompt" -ForegroundColor Yellow
  # [void] matters: Read-Host emits the typed string, which would otherwise
  # ride along in this function's return value and displace the readings.
  [void](Read-Host "     hold it there and press Enter")
  $r = Read-Axes
  Write-Host ("     read: " + (($names | ForEach-Object { "$_=$($r[$_])" }) -join "  ")) -ForegroundColor DarkGray
  return $r
}

Write-Host ""
Write-Host "  GUIDED AXIS MAPPING - T.Flight Hotas One" -ForegroundColor Cyan
Write-Host "  =================================================="
Write-Host "  One control at a time. Hold each position, press Enter."

$base = Step-Capture "Centre the stick, centre the rudder rocker, throttle lever to MIDDLE."
$thF  = Step-Capture "Push the THROTTLE LEVER fully FORWARD (away from you)."
$thB  = Step-Capture "Pull the THROTTLE LEVER fully BACK (toward you)."
$rkR  = Step-Capture "Push the RUDDER ROCKER fully RIGHT."
$stR  = Step-Capture "Hold the STICK fully RIGHT."
$stF  = Step-Capture "Hold the STICK fully FORWARD (nose down)."

function Best($a, $b) {
  $bestN = ""; $bestD = 0
  foreach ($n in $names) {
    $d = [Math]::Abs($a[$n] - $b[$n])
    if ($d -gt $bestD) { $bestD = $d; $bestN = $n }
  }
  return @($bestN, $bestD)
}

$out = @()
$out += "GUIDED AXIS MAP - T.Flight Hotas One"
$out += "===================================="
$out += ""
$out += ("baseline: " + (($names | ForEach-Object { "$_=$($base[$_])" }) -join "  "))
$out += ""

$tf = Best $thF $base; $tb = Best $thB $base
$rk = Best $rkR $base; $sr = Best $stR $base; $sf = Best $stF $base

$out += ("THROTTLE fwd   -> axis {0,-2} ({1,-12}) delta {2}   raw {3}" -f $tf[0], $sc[$tf[0]], $tf[1], $thF[$tf[0]])
$out += ("THROTTLE back  -> axis {0,-2} ({1,-12}) delta {2}   raw {3}" -f $tb[0], $sc[$tb[0]], $tb[1], $thB[$tb[0]])
$out += ("RUDDER right   -> axis {0,-2} ({1,-12}) delta {2}   raw {3}" -f $rk[0], $sc[$rk[0]], $rk[1], $rkR[$rk[0]])
$out += ("STICK right    -> axis {0,-2} ({1,-12}) delta {2}   raw {3}" -f $sr[0], $sc[$sr[0]], $sr[1], $stR[$sr[0]])
$out += ("STICK forward  -> axis {0,-2} ({1,-12}) delta {2}   raw {3}" -f $sf[0], $sc[$sf[0]], $sf[1], $stF[$sf[0]])
$out += ""

if ($tf[0] -eq $tb[0] -and $tf[0] -ne "") {
  $fwd = $thF[$tf[0]]; $bck = $thB[$tf[0]]
  if ($fwd -gt $bck) {
    $out += "THROTTLE POLARITY: forward = HIGHER raw ($fwd vs $bck) -> normal, no invert needed"
  } else {
    $out += "THROTTLE POLARITY: forward = LOWER raw ($fwd vs $bck) -> INVERTED, needs inversion"
  }
} else {
  $out += "THROTTLE POLARITY: inconclusive - forward and back picked different axes"
}

$p = "$PSScriptRoot\axis-map.txt"
$out | Set-Content -Path $p -Encoding utf8
Write-Host ""
$out | ForEach-Object { Write-Host "  $_" }
Write-Host ""
Write-Host "  Saved to $p" -ForegroundColor Green
