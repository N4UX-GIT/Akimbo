# Run in a fresh PowerShell process. Native calls are simulated; no game is moved.
$ErrorActionPreference = 'Stop'
Add-Type @"
using System;
public static class OffhandNative {
 public struct Rect { public int Left,Top,Right,Bottom; }
 public static Rect Current = new Rect {Left=10,Top=20,Right=810,Bottom=620};
 public static int Style=0x00C40000, Moves=0, Restores=0;
 public static uint Owner=42;
 public static bool Reject=false, Maximized=true, Minimized=false;
 public static IntPtr Dpi=new IntPtr(1);
 public static IntPtr SetThreadDpiAwarenessContext(IntPtr c) { var old=Dpi; Dpi=c; return old; }
 public static int GetSystemMetrics(int i) { return i==76 ? -1440 : i==77 ? -1114 : i==78 ? 4000 : 2560; }
 public static uint GetWindowThreadProcessId(IntPtr h,out uint p) {p=Owner;return 1;}
 public static IntPtr FindProcessWindow(int id) {return new IntPtr(99);}
 public static bool IsZoomed(IntPtr h) {return Maximized;}
 public static bool IsIconic(IntPtr h) {return Minimized;}
 public static bool ShowWindow(IntPtr h,int cmd) {Restores++;Maximized=false;Minimized=false;return true;}
 public static bool GetWindowRect(IntPtr h,out Rect r) {r=Current;return true;}
 public static int GetWindowLong(IntPtr h,int i) {return Style;}
 public static void SetLastError(uint e) {}
 public static int SetWindowLong(IntPtr h,int i,int v) {int old=Style;Style=v;return old;}
 public static bool SetWindowPos(IntPtr h,IntPtr z,int x,int y,int w,int ht,uint flags) {
  Moves++;
  if (Reject) {Reject=false;return false;}
  Current=new Rect {Left=x,Top=y,Right=x+w,Bottom=y+ht};return true;
 }
}
"@
. (Join-Path $PSScriptRoot '..\Companion\Offhand-Window.ps1')
function Assert($condition, $message) { if (-not $condition) { throw $message } }
# Simulate installation files without reading or changing a real client's files.
function Test-Path { param($LiteralPath,$PathType) return ($LiteralPath.EndsWith('Offhand_Vanilla.toc') -or $LiteralPath.EndsWith('Akimbo_Vanilla.toc')) }
$fake = [pscustomobject]@{Id=42;MainWindowHandle=[IntPtr]99;MainModule=@{FileName='C:\OffhandTest\WowClassic.exe'}}
$fake | Add-Member ScriptMethod Refresh {}
$status = Test-OffhandAddonStatus $fake
Assert $status.Installed 'Vanilla TOC not recognized'
Assert ($null -eq $status.Enabled) 'Installation was misreported as enabled'
Assert (-not (Test-OffhandAddonStatus $null).Installed) 'Absent client passed gate'
$unreadable = [pscustomobject]@{MainModule=$null}
Assert (-not (Test-OffhandAddonStatus $unreadable).Installed) 'Unreadable client passed gate'
$bounds = Invoke-OffhandSpan $fake
Assert ($bounds.X -eq -1440 -and $bounds.Y -eq -1114 -and $bounds.Width -eq 4000 -and $bounds.Height -eq 2560) 'Incorrect span geometry'
Assert ([OffhandNative]::Restores -eq 1) 'Maximized window not restored'
Assert ([OffhandNative]::Style -eq 0) 'Borders not removed'
Assert ([OffhandNative]::Dpi -eq [IntPtr]1) 'DPI context not restored'
[OffhandNative]::Minimized=$true
[void](Invoke-OffhandSpan $fake)
Assert ([OffhandNative]::Restores -eq 2) 'Minimized window not restored'
$oldRect=[OffhandNative]::Current
[OffhandNative]::Style=0x00C40000
[OffhandNative]::Reject=$true
$failed=$false
try { Invoke-OffhandSpan $fake } catch { $failed=$true }
Assert $failed 'Rejected span reported success'
Assert ([OffhandNative]::Style -eq 0x00C40000 -and [OffhandNative]::Current.Left -eq $oldRect.Left) 'Failed span not rolled back'
Assert ([OffhandNative]::Dpi -eq [IntPtr]1) 'Failed span leaked DPI context'
[OffhandNative]::Owner=999
$moves=[OffhandNative]::Moves
$failed=$false
try { Invoke-OffhandSpan $fake } catch { $failed=$true }
Assert ($failed -and [OffhandNative]::Moves -eq $moves) 'Wrong-process window was moved'
function Get-Process { return @($fake,$fake) }
Assert ($null -eq (Get-WoWProcess)) 'Multiple clients were silently selected'
Write-Output 'PASS: install/unknown state, physical geometry, restore, rollback, DPI cleanup, process ownership, multiple-client refusal'
