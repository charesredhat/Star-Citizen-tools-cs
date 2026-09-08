Add-Type @"
using System;
using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential)]
public struct JOYINFOEX {
  public uint dwSize, dwFlags;
  public uint dwXpos, dwYpos, dwZpos, dwRpos, dwUpos, dwVpos;
  public uint dwButtons, dwButtonNumber, dwPOV, dwReserved1, dwReserved2;
}
public class JoyQ {
  [DllImport("winmm.dll")] public static extern uint joyGetPosEx(uint id, ref JOYINFOEX pji);
}
"@
$names = @("X","Y","Z","R","U","V")
$sc = @{ "X"="js1_x"; "Y"="js1_y"; "Z"="js1_z"; "R"="js1_rotz"; "U"="js1_slider1"; "V"="js1_slider2" }
$min = @{}; $max = @{}
foreach ($n in $names) { $min[$n] = [uint32]::MaxValue; $max[$n] = [uint32]0 }
$p = New-Object JOYINFOEX
$p.dwSize = [System.Runtime.InteropServices.Marshal]::SizeOf($p)
$p.dwFlags = 0xff
$samples = 0; $fails = 0
$end = (Get-Date).AddSeconds(8)
while ((Get-Date) -lt $end) {
  $r = [JoyQ]::joyGetPosEx(0, [ref]$p)
  if ($r -eq 0) {
    $samples++
    $vals = @($p.dwXpos,$p.dwYpos,$p.dwZpos,$p.dwRpos,$p.dwUpos,$p.dwVpos)
    for ($i=0; $i -lt 6; $i++) {
      $n=$names[$i]; $v=$vals[$i]
      if ($v -lt $min[$n]) { $min[$n]=$v }
      if ($v -gt $max[$n]) { $max[$n]=$v }
    }
  } else { $fails++ }
  Start-Sleep -Milliseconds 25
}
"samples=$samples  failed_reads=$fails"
""
"axis   sc_token       min      max      travel   resting"
"-----  -------------  -------  -------  -------  -------"
foreach ($n in $names) {
  $t = [int]$max[$n] - [int]$min[$n]
  $rest = if ($max[$n] -eq 32767 -and $t -eq 0) { "CENTER (32767)" } elseif ($t -eq 0) { "parked at $($max[$n])" } else { "moving" }
  "{0,-5}  {1,-13}  {2,-7}  {3,-7}  {4,-7}  {5}" -f $n, $sc[$n], $min[$n], $max[$n], $t, $rest
}
