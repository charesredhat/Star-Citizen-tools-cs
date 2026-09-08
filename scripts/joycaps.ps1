Add-Type @"
using System;
using System.Runtime.InteropServices;
[StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
public struct JOYCAPS {
  public ushort wMid; public ushort wPid;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string szPname;
  public uint wXmin, wXmax, wYmin, wYmax, wZmin, wZmax;
  public uint wNumButtons; public uint wPeriodMin, wPeriodMax;
  public uint wRmin, wRmax, wUmin, wUmax, wVmin, wVmax;
  public uint wCaps; public uint wMaxAxes, wNumAxes, wMaxButtons;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string szRegKey;
  [MarshalAs(UnmanagedType.ByValTStr, SizeConst=260)] public string szOEMVxD;
}
[StructLayout(LayoutKind.Sequential)]
public struct JOYINFOEX {
  public uint dwSize, dwFlags;
  public uint dwXpos, dwYpos, dwZpos, dwRpos, dwUpos, dwVpos;
  public uint dwButtons, dwButtonNumber, dwPOV, dwReserved1, dwReserved2;
}
public class Joy {
  [DllImport("winmm.dll")] public static extern uint joyGetNumDevs();
  [DllImport("winmm.dll", CharSet=CharSet.Unicode)] public static extern uint joyGetDevCapsW(UIntPtr id, ref JOYCAPS c, uint cb);
  [DllImport("winmm.dll")] public static extern uint joyGetPosEx(uint id, ref JOYINFOEX pji);
}
"@

"winmm reports $([Joy]::joyGetNumDevs()) joystick slots`n"

for ($i = 0; $i -lt 8; $i++) {
  $c = New-Object JOYCAPS
  $r = [Joy]::joyGetDevCapsW([UIntPtr]::new($i), [ref]$c, [System.Runtime.InteropServices.Marshal]::SizeOf($c))
  if ($r -ne 0) { continue }
  if ([string]::IsNullOrWhiteSpace($c.szPname)) { continue }

  "=== joystick id $i : $($c.szPname) ==="
  "  VID/PID    : {0:X4}:{1:X4}" -f $c.wMid, $c.wPid
  "  axes       : $($c.wNumAxes) of max $($c.wMaxAxes)"
  "  buttons    : $($c.wNumButtons) of max $($c.wMaxButtons)"
  $caps = @()
  if ($c.wCaps -band 0x1)  { $caps += "HASZ (z axis)" }
  if ($c.wCaps -band 0x2)  { $caps += "HASR (r / rudder)" }
  if ($c.wCaps -band 0x4)  { $caps += "HASU (u / slider1)" }
  if ($c.wCaps -band 0x8)  { $caps += "HASV (v / slider2)" }
  if ($c.wCaps -band 0x10) { $caps += "HASPOV (hat)" }
  "  capability : $($caps -join ', ')"
  "  ranges     : X[$($c.wXmin)-$($c.wXmax)] Y[$($c.wYmin)-$($c.wYmax)] Z[$($c.wZmin)-$($c.wZmax)]"
  "               R[$($c.wRmin)-$($c.wRmax)] U[$($c.wUmin)-$($c.wUmax)] V[$($c.wVmin)-$($c.wVmax)]"

  $p = New-Object JOYINFOEX
  $p.dwSize = [System.Runtime.InteropServices.Marshal]::SizeOf($p)
  $p.dwFlags = 0xff
  if ([Joy]::joyGetPosEx($i, [ref]$p) -eq 0) {
    "  live now   : X=$($p.dwXpos) Y=$($p.dwYpos) Z=$($p.dwZpos) R=$($p.dwRpos) U=$($p.dwUpos) V=$($p.dwVpos) POV=$($p.dwPOV) buttons=0x$('{0:X}' -f $p.dwButtons)"
  }
  ""
}
