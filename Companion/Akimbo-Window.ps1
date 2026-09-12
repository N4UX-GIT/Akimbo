# Shared window operations. Dot-sourcing this file does not resize any window.
Add-Type -AssemblyName System.Windows.Forms
if (-not ('AkimboNative' -as [type])) {
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class AkimboNative {
    public delegate bool EnumProc(IntPtr hwnd, IntPtr param);
    [StructLayout(LayoutKind.Sequential)] public struct Rect { public int Left, Top, Right, Bottom; }
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr param);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool IsZoomed(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hwnd, int cmd);
    [DllImport("user32.dll")] public static extern int GetWindowLong(IntPtr hwnd, int index);
    [DllImport("user32.dll", SetLastError=true)] public static extern int SetWindowLong(IntPtr hwnd, int index, int value);
    [DllImport("kernel32.dll")] public static extern void SetLastError(uint error);
    [DllImport("user32.dll", SetLastError=true)] public static extern bool SetWindowPos(IntPtr hwnd, IntPtr after, int x, int y, int w, int h, uint flags);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out Rect rect);
    [DllImport("user32.dll")] public static extern int GetSystemMetrics(int index);
    [DllImport("user32.dll", SetLastError=true)] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr context);
    public static IntPtr FindProcessWindow(int processId) {
        IntPtr found = IntPtr.Zero;
        EnumWindows(delegate(IntPtr h, IntPtr p) {
            uint id; GetWindowThreadProcessId(h, out id);
            if (id == processId && IsWindowVisible(h)) { found=h; return false; }
            return true;
        }, IntPtr.Zero);
        return found;
    }
}
"@
}

function Get-WoWProcess {
    # Do not silently choose a client when multiple games are running.
    $candidates = @(Get-Process -Name WowClassic, Wow, WowClassicEra -ErrorAction SilentlyContinue)
    if ($candidates.Count -eq 1) { return $candidates[0] }
}

function Test-AkimboAddonStatus {
    param($proc)
    $result = @{ Installed=$false; Enabled=$null; WowDir=$null; Reason='Launch exactly one WoW client.' }
    if (-not $proc) { return $result }
    try {
        $result.WowDir = Split-Path -Parent $proc.MainModule.FileName
        if (-not $result.WowDir) { throw 'Client path unavailable.' }
        $directory = Join-Path $result.WowDir 'Interface\AddOns\Akimbo'
        $manifests = @('Akimbo.toc', 'Akimbo_Vanilla.toc')
        foreach ($manifest in $manifests) {
            if (Test-Path -LiteralPath (Join-Path $directory $manifest) -PathType Leaf) {
                $result.Installed = $true
                break
            }
        }
        if ($result.Installed) {
            $result.Reason = 'Installed; confirm enabled in WoW. Live addon state is unavailable.'
        } else { $result.Reason = 'Install Akimbo in this client''s Interface\AddOns folder.' }
    } catch { $result.Reason = 'Cannot verify the addon installation for this client.' }
    # AddOns.txt from arbitrary characters cannot establish the active character's
    # state. Do not report either enabled or disabled from that unrelated data.
    return $result
}

function Get-WoWWindowHandle {
    param($proc)
    if (-not $proc) { return [IntPtr]::Zero }
    $proc.Refresh()
    $handle = $proc.MainWindowHandle
    if ($handle -eq [IntPtr]::Zero) { $handle = [AkimboNative]::FindProcessWindow($proc.Id) }
    [uint32]$owner = 0
    [void][AkimboNative]::GetWindowThreadProcessId($handle, [ref]$owner)
    if ($owner -ne $proc.Id) { return [IntPtr]::Zero }
    return $handle
}

function Get-AkimboDesktopBounds {
    $previousDpi = [AkimboNative]::SetThreadDpiAwarenessContext([IntPtr](-4))
    if ($previousDpi -eq [IntPtr]::Zero) { throw 'Physical display coordinates unavailable.' }
    try {
        return [pscustomobject]@{
            X=[AkimboNative]::GetSystemMetrics(76); Y=[AkimboNative]::GetSystemMetrics(77)
            Width=[AkimboNative]::GetSystemMetrics(78); Height=[AkimboNative]::GetSystemMetrics(79)
        }
    } finally { [void][AkimboNative]::SetThreadDpiAwarenessContext($previousDpi) }
}

function Invoke-AkimboSpan {
    param($proc)
    $status = Test-AkimboAddonStatus $proc
    if (-not $status.Installed) { throw $status.Reason }
    $handle = Get-WoWWindowHandle $proc
    if ($handle -eq [IntPtr]::Zero) { throw 'WoW window is not ready. Retry after it opens.' }
    # Use physical desktop coordinates even when monitors have different DPI.
    $previousDpi = [AkimboNative]::SetThreadDpiAwarenessContext([IntPtr](-4))
    if ($previousDpi -eq [IntPtr]::Zero) { throw 'Physical display coordinates unavailable on this Windows version.' }
    try {
        $x = [AkimboNative]::GetSystemMetrics(76)
        $y = [AkimboNative]::GetSystemMetrics(77)
        $width = [AkimboNative]::GetSystemMetrics(78)
        $height = [AkimboNative]::GetSystemMetrics(79)
        if ($width -le 0 -or $height -le 0) { throw 'Invalid virtual desktop dimensions.' }
        if ([AkimboNative]::IsZoomed($handle) -or [AkimboNative]::IsIconic($handle)) {
            [void][AkimboNative]::ShowWindow($handle, 9)
        }
        $oldRect = New-Object AkimboNative+Rect
        if (-not [AkimboNative]::GetWindowRect($handle, [ref]$oldRect)) { throw 'Could not read WoW window bounds.' }
        # GWL_STYLE is a 32-bit value on both 32-bit and 64-bit Windows.
        $oldStyle = [AkimboNative]::GetWindowLong($handle, -16)
        $style = $oldStyle -band (-bnot (0x00C00000 -bor 0x00040000))
        if ($style -ne $oldStyle) {
            [AkimboNative]::SetLastError(0)
            $old = [AkimboNative]::SetWindowLong($handle, -16, $style)
            if ($old -eq 0 -and [Runtime.InteropServices.Marshal]::GetLastWin32Error() -ne 0) {
                throw 'Could not remove WoW window borders.'
            }
        }
        try {
            # Preserve z-order and focus; only change the selected game's geometry.
            if (-not [AkimboNative]::SetWindowPos($handle, [IntPtr]::Zero, $x, $y, $width, $height, 0x0074)) {
                throw 'Windows rejected the requested span.'
            }
            $actual = New-Object AkimboNative+Rect
            if (-not [AkimboNative]::GetWindowRect($handle, [ref]$actual) -or
                $actual.Left -ne $x -or $actual.Top -ne $y -or
                ($actual.Right-$actual.Left) -ne $width -or ($actual.Bottom-$actual.Top) -ne $height) {
                throw 'WoW did not accept the requested bounds. Select Windowed mode and retry.'
            }
        } catch {
            [void][AkimboNative]::SetWindowLong($handle, -16, $oldStyle)
            [void][AkimboNative]::SetWindowPos($handle, [IntPtr]::Zero, $oldRect.Left, $oldRect.Top,
                ($oldRect.Right-$oldRect.Left), ($oldRect.Bottom-$oldRect.Top), 0x0074)
            throw
        }
        return [pscustomobject]@{ X=$x; Y=$y; Width=$width; Height=$height }
    } finally { [void][AkimboNative]::SetThreadDpiAwarenessContext($previousDpi) }
}
