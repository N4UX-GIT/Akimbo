# ==============================================================================
# Akimbo Companion: Multi-Monitor Desktop Controller & Background Watcher
# Native Windows GUI with System Tray, Auto-Spanning, and Addon Validation
# Classic Warcraft Theme
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

. (Join-Path $PSScriptRoot 'Akimbo-Window.ps1')

# ==============================================================================
# Suppress all PowerShell terminal windows
# AkimboNative is already available from Akimbo-Window.ps1
# ==============================================================================
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class AkimboConsole {
    [DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow();
    [DllImport("user32.dll")]   public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

# Hide our own console window immediately
$consoleHwnd = [AkimboConsole]::GetConsoleWindow()
if ($consoleHwnd -ne [IntPtr]::Zero) {
    [void][AkimboConsole]::ShowWindow($consoleHwnd, 0)
}

# Hide any other PowerShell terminal windows (but not our companion GUI)
$myPid = [System.Diagnostics.Process]::GetCurrentProcess().Id
$psProcs = @(Get-Process -Name 'powershell','pwsh' -ErrorAction SilentlyContinue |
             Where-Object { $_.Id -ne $myPid -and $_.MainWindowHandle -ne [IntPtr]::Zero })
foreach ($p in $psProcs) {
    [void][AkimboNative]::ShowWindow($p.MainWindowHandle, 0)
}

# ==============================================================================
# Dark Metal & Blue Color Palette
# ==============================================================================
$cBg           = [System.Drawing.Color]::FromArgb(8, 10, 18)          # Near-black deep metal
$cCard         = [System.Drawing.Color]::FromArgb(17, 24, 38)         # Dark steel card
$cBorder       = [System.Drawing.Color]::FromArgb(58, 74, 94)         # Forged steel rim
$cBorderDim    = [System.Drawing.Color]::FromArgb(26, 48, 80)         # Dim blue border
$cText         = [System.Drawing.Color]::FromArgb(216, 232, 245)      # Cool arctic white
$cMuted        = [System.Drawing.Color]::FromArgb(122, 150, 176)      # Steel grey muted
$cGold         = [System.Drawing.Color]::FromArgb(42, 144, 232)       # Blue glow primary
$cGoldBright   = [System.Drawing.Color]::FromArgb(90, 184, 255)       # Blue highlight
$cBrass        = [System.Drawing.Color]::FromArgb(180, 138, 52)       # Antique brass (secondary trim)
$cGreen        = [System.Drawing.Color]::FromArgb(68, 204, 136)       # Status green
$cRed          = [System.Drawing.Color]::FromArgb(204, 68, 68)        # Status red
$cYellow       = [System.Drawing.Color]::FromArgb(220, 180, 60)       # Warning amber
$cBtnBg        = [System.Drawing.Color]::FromArgb(26, 36, 56)         # Button dark metal
$cBtnDanger    = [System.Drawing.Color]::FromArgb(40, 16, 16)         # Danger button
$cLogBg        = [System.Drawing.Color]::FromArgb(6, 8, 14)           # Log deep black
$cLogText      = [System.Drawing.Color]::FromArgb(140, 180, 218)      # Log cool steel text

# ==============================================================================
# Helper: Styled Button with gold border
# ==============================================================================
function New-StyledButton {
    param($text, $x, $y, $w, $h, $bgColor, $textColor, $borderColor)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Size = New-Object System.Drawing.Size($w, $h)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 1
    $btn.FlatAppearance.BorderColor = if ($borderColor) { $borderColor } else { $cBorder }
    $btn.BackColor = $bgColor
    $btn.ForeColor = $textColor
    $btn.Font = New-Object System.Drawing.Font("Georgia", 9, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $btn
}

# Helper: card panel with gold border drawn via Paint
function New-CardPanel {
    param($x, $y, $w, $h, $title)
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($x, $y)
    $panel.Size = New-Object System.Drawing.Size($w, $h)
    $panel.BackColor = $cCard

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "  $title"
    $lbl.Location = New-Object System.Drawing.Point(0, 4)
    $lbl.Size = New-Object System.Drawing.Size($w, 20)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = $cGold
    $panel.Controls.Add($lbl)

    $panel.add_Paint({
        param($s, $e)
        $g = $e.Graphics
        $pen = New-Object System.Drawing.Pen($cBorder, 1)
        $g.DrawRectangle($pen, 0, 0, $s.ClientSize.Width - 1, $s.ClientSize.Height - 1)
        $pen.Dispose()
        $penDim = New-Object System.Drawing.Pen($cBorderDim, 1)
        $g.DrawLine($penDim, 1, 24, $s.ClientSize.Width - 2, 24)
        $penDim.Dispose()
    })
    return $panel
}

# ==============================================================================
# Main Window
# ==============================================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Akimbo Companion"
$form.Size = New-Object System.Drawing.Size(524, 628)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $cBg
$form.ForeColor = $cText

# ==============================================================================
# HEADER — Logo + Title
# ==============================================================================
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size = New-Object System.Drawing.Size(524, 90)
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(10, 14, 24)
$form.Controls.Add($headerPanel)

$headerPanel.add_Paint({
    param($s, $e)
    $pen = New-Object System.Drawing.Pen($cBorder, 2)
    $e.Graphics.DrawLine($pen, 0, $s.Height - 1, $s.Width, $s.Height - 1)
    $pen.Dispose()
})

# Logo image
$logoPicBox = New-Object System.Windows.Forms.PictureBox
$logoPicBox.Location = New-Object System.Drawing.Point(8, 5)
$logoPicBox.Size = New-Object System.Drawing.Size(80, 80)
$logoPicBox.SizeMode = "Zoom"
$logoPicBox.BackColor = [System.Drawing.Color]::Transparent

$logoCandidates = @(
    (Join-Path $PSScriptRoot "..\Media\akimbo-logo.png"),
    "C:\Users\NAUX\.gemini\antigravity\brain\937603db-0268-4223-88ae-effc8cc5441c\.user_uploaded\media_1789282129946.png",
    (Join-Path $PSScriptRoot "..\Media\akimbo-logo.jpg")
)
foreach ($path in $logoCandidates) {
    if (Test-Path $path -ErrorAction SilentlyContinue) {
        try { $logoPicBox.Image = [System.Drawing.Image]::FromFile($path); break } catch { }
    }
}
$headerPanel.Controls.Add($logoPicBox)

$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "AKIMBO"
$titleLabel.Location = New-Object System.Drawing.Point(96, 10)
$titleLabel.Size = New-Object System.Drawing.Size(400, 36)
$titleLabel.Font = New-Object System.Drawing.Font("Georgia", 22, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $cGold
$titleLabel.BackColor = [System.Drawing.Color]::Transparent
$headerPanel.Controls.Add($titleLabel)

$subLabel = New-Object System.Windows.Forms.Label
$subLabel.Text = "Dual-Monitor Companion for World of Warcraft"
$subLabel.Location = New-Object System.Drawing.Point(98, 50)
$subLabel.Size = New-Object System.Drawing.Size(400, 18)
$subLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$subLabel.ForeColor = $cMuted
$subLabel.BackColor = [System.Drawing.Color]::Transparent
$headerPanel.Controls.Add($subLabel)

$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "v1.2"
$versionLabel.Location = New-Object System.Drawing.Point(98, 68)
$versionLabel.Size = New-Object System.Drawing.Size(100, 14)
$versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Italic)
$versionLabel.ForeColor = $cMuted
$versionLabel.BackColor = [System.Drawing.Color]::Transparent
$headerPanel.Controls.Add($versionLabel)

# ==============================================================================
# STATUS CARD
# ==============================================================================
$statusPanel = New-CardPanel -x 16 -y 102 -w 490 -h 118 -title "System Status"
$form.Controls.Add($statusPanel)

$lblWowStatus = New-Object System.Windows.Forms.Label
$lblWowStatus.Text = "  WoW Process: Checking..."
$lblWowStatus.Location = New-Object System.Drawing.Point(0, 30)
$lblWowStatus.Size = New-Object System.Drawing.Size(490, 20)
$lblWowStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblWowStatus.ForeColor = $cMuted
$statusPanel.Controls.Add($lblWowStatus)

$lblAddonStatus = New-Object System.Windows.Forms.Label
$lblAddonStatus.Text = "  Akimbo Addon: Checking..."
$lblAddonStatus.Location = New-Object System.Drawing.Point(0, 54)
$lblAddonStatus.Size = New-Object System.Drawing.Size(490, 20)
$lblAddonStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblAddonStatus.ForeColor = $cMuted
$statusPanel.Controls.Add($lblAddonStatus)

$lblDisplayInfo = New-Object System.Windows.Forms.Label
$lblDisplayInfo.Text = "  Virtual Desktop: Checking..."
$lblDisplayInfo.Location = New-Object System.Drawing.Point(0, 78)
$lblDisplayInfo.Size = New-Object System.Drawing.Size(490, 18)
$lblDisplayInfo.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblDisplayInfo.ForeColor = $cMuted
$statusPanel.Controls.Add($lblDisplayInfo)

$lblAddonReason = New-Object System.Windows.Forms.Label
$lblAddonReason.Text = ""
$lblAddonReason.Location = New-Object System.Drawing.Point(0, 98)
$lblAddonReason.Size = New-Object System.Drawing.Size(490, 16)
$lblAddonReason.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Italic)
$lblAddonReason.ForeColor = $cYellow
$statusPanel.Controls.Add($lblAddonReason)

# ==============================================================================
# CONFIGURATION CARD
# ==============================================================================
$configPanel = New-CardPanel -x 16 -y 230 -w 490 -h 54 -title "Configuration"
$form.Controls.Add($configPanel)

$chkAutoSpan = New-Object System.Windows.Forms.CheckBox
$chkAutoSpan.Text = "Automatically span WoW window on game launch"
$chkAutoSpan.Location = New-Object System.Drawing.Point(10, 28)
$chkAutoSpan.Size = New-Object System.Drawing.Size(460, 22)
$chkAutoSpan.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$chkAutoSpan.ForeColor = $cText
$chkAutoSpan.BackColor = [System.Drawing.Color]::Transparent
$chkAutoSpan.Checked = $true
$configPanel.Controls.Add($chkAutoSpan)

# ==============================================================================
# ACTION BUTTONS
# ==============================================================================
$btnSpanNow = New-StyledButton -text "Span WoW Window Now" -x 16 -y 296 -w 238 -h 36 `
    -bgColor $cBtnBg -textColor $cGold -borderColor $cBorder
$form.Controls.Add($btnSpanNow)

$btnToggleWatch = New-StyledButton -text "Pause Monitoring" -x 262 -y 296 -w 244 -h 36 `
    -bgColor $cBtnBg -textColor $cText -borderColor $cBorderDim
$form.Controls.Add($btnToggleWatch)

# ==============================================================================
# ACTIVITY LOG CARD
# ==============================================================================
$logPanel = New-CardPanel -x 16 -y 344 -w 490 -h 200 -title "Activity Log"
$form.Controls.Add($logPanel)

$logBox = New-Object System.Windows.Forms.ListBox
$logBox.Location = New-Object System.Drawing.Point(4, 28)
$logBox.Size = New-Object System.Drawing.Size(482, 166)
$logBox.BackColor = $cLogBg
$logBox.ForeColor = $cLogText
$logBox.BorderStyle = "None"
$logBox.Font = New-Object System.Drawing.Font("Consolas", 8.5)
$logPanel.Controls.Add($logBox)

# ==============================================================================
# FOOTER BUTTONS
# ==============================================================================
$btnMinimize = New-StyledButton -text "Minimize to Tray" -x 16 -y 556 -w 152 -h 30 `
    -bgColor $cBtnBg -textColor $cMuted -borderColor $cBorderDim
$form.Controls.Add($btnMinimize)

$btnExit = New-StyledButton -text "Exit Companion" -x 356 -y 556 -w 152 -h 30 `
    -bgColor $cBtnDanger -textColor $cRed `
    -borderColor ([System.Drawing.Color]::FromArgb(120, 50, 40))
$form.Controls.Add($btnExit)

# ==============================================================================
# LOGGING HELPER
# ==============================================================================
function Add-Log {
    param($msg)
    $time = (Get-Date).ToString("HH:mm:ss")
    $logBox.Items.Insert(0, "[$time] $msg")
    while ($logBox.Items.Count -gt 100) {
        $logBox.Items.RemoveAt($logBox.Items.Count - 1)
    }
}

# ==============================================================================
# SYSTEM TRAY ICON
# ==============================================================================
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Text = "Akimbo Companion"
$trayIcon.Visible = $true

$bmp = New-Object System.Drawing.Bitmap 16, 16
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(8, 10, 18))
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(90, 184, 255))
$fontIcon = New-Object System.Drawing.Font("Georgia", 9, [System.Drawing.FontStyle]::Bold)
$g.DrawString("A", $fontIcon, $brush, 1, 0)
$g.Dispose(); $brush.Dispose(); $fontIcon.Dispose()
$hIcon = $bmp.GetHicon()
$trayIcon.Icon = [System.Drawing.Icon]::FromHandle($hIcon)

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$trayMenu.BackColor = $cCard
$trayMenu.ForeColor = $cText
$itemOpen = $trayMenu.Items.Add("Open Dashboard")
$trayMenu.Items.Add("-")
$itemSpan = $trayMenu.Items.Add("Span WoW Now")
$itemAuto = $trayMenu.Items.Add("Auto-Span Enabled")
$itemAuto.Checked = $true
$trayMenu.Items.Add("-")
$itemExit = $trayMenu.Items.Add("Exit")
$trayIcon.ContextMenuStrip = $trayMenu

$trayIcon.add_DoubleClick({
    $form.Show(); $form.WindowState = "Normal"; $form.Activate()
})
$itemOpen.add_Click({
    $form.Show(); $form.WindowState = "Normal"; $form.Activate()
})
$itemAuto.add_Click({
    $chkAutoSpan.Checked = -not $chkAutoSpan.Checked
    $itemAuto.Checked = $chkAutoSpan.Checked
})

# ==============================================================================
# SPAN LOGIC
# ==============================================================================
function Invoke-SpanWindow {
    param([bool]$manual = $false)
    try {
        $bounds = Invoke-AkimboSpan (Get-WoWProcess)
        Add-Log "Spanned $($bounds.Width)x$($bounds.Height). Calibrate with /akimbo wizard."
        $trayIcon.ShowBalloonTip(3000, "Akimbo Spanned", "Window spanned. Use /akimbo wizard to calibrate.", "Info")
        return $true
    } catch {
        Add-Log $_.Exception.Message
        if ($manual) {
            [void][System.Windows.Forms.MessageBox]::Show($_.Exception.Message, "Akimbo", "OK", "Information")
        }
        return $false
    }
}

# ==============================================================================
# BACKGROUND WATCHER TIMER
# ==============================================================================
$isMonitoring = $true
$spannedPids  = @{}
$retryAfter   = @{}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000

$timer.add_Tick({
    try {
        $vs = Get-AkimboDesktopBounds
        $lblDisplayInfo.Text = "  Virtual Desktop: $($vs.Width) x $($vs.Height) px  (Offset X:$($vs.X), Y:$($vs.Y))"
    } catch {
        $lblDisplayInfo.Text = "  Virtual Desktop: physical coordinates unavailable"
    }

    $proc = Get-WoWProcess
    if ($proc) {
        $lblWowStatus.Text = "  ● WoW Running  ($($proc.ProcessName)  PID: $($proc.Id))"
        $lblWowStatus.ForeColor = $cGreen

        $status = Test-AkimboAddonStatus -proc $proc
        if ($status.Installed) {
            $lblAddonStatus.Text = "  ● Akimbo Addon: INSTALLED"
            $lblAddonStatus.ForeColor = $cGreen
            $lblAddonReason.Text = "  Confirm Akimbo is enabled in the current WoW session."
        } else {
            $lblAddonStatus.Text = "  ○ Akimbo Addon: NOT VERIFIED"
            $lblAddonStatus.ForeColor = $cRed
            $lblAddonReason.Text = "  $($status.Reason)"
        }

        if ($isMonitoring -and $chkAutoSpan.Checked -and $status.Installed) {
            if (-not $spannedPids.ContainsKey($proc.Id) -and
                (-not $retryAfter.ContainsKey($proc.Id) -or (Get-Date) -ge $retryAfter[$proc.Id])) {
                Add-Log "New WoW launch detected (PID: $($proc.Id)). Preparing auto-span..."
                $retryAfter[$proc.Id] = (Get-Date).AddSeconds(10)
                if (Invoke-SpanWindow -manual $false) { $spannedPids[$proc.Id] = $true }
            }
        }
    } else {
        $lblWowStatus.Text = "  ○ WoW Process: Not running"
        $lblWowStatus.ForeColor = $cMuted
        $lblAddonStatus.Text = "  ○ Akimbo Addon: Waiting for WoW..."
        $lblAddonStatus.ForeColor = $cMuted
        $lblAddonReason.Text = ""
    }

    $keys = @($spannedPids.Keys)
    foreach ($k in $keys) {
        if (-not (Get-Process -Id $k -ErrorAction SilentlyContinue)) {
            $spannedPids.Remove($k); $retryAfter.Remove($k)
            Add-Log "WoW process (PID: $k) closed."
        }
    }
})

# ==============================================================================
# UI EVENT HANDLERS
# ==============================================================================
$btnSpanNow.add_Click({ Invoke-SpanWindow -manual $true })

$btnToggleWatch.add_Click({
    $isMonitoring = -not $isMonitoring
    if ($isMonitoring) {
        $btnToggleWatch.Text = "Pause Monitoring"
        $btnToggleWatch.ForeColor = $cText
        Add-Log "Background auto-watcher resumed."
    } else {
        $btnToggleWatch.Text = "Resume Monitoring"
        $btnToggleWatch.ForeColor = $cYellow
        Add-Log "Background auto-watcher PAUSED by user."
    }
})

$chkAutoSpan.add_CheckedChanged({
    $itemAuto.Checked = $chkAutoSpan.Checked
    Add-Log "Auto-Span on launch: $($chkAutoSpan.Checked)"
})

$btnMinimize.add_Click({
    $form.Hide()
    $trayIcon.ShowBalloonTip(2000, "Akimbo Running in Tray",
        "Monitoring in background. Double-click tray icon to restore.", "Info")
})

$btnExit.add_Click({
    $timer.Stop(); $trayIcon.Visible = $false
    $form.Close(); [System.Windows.Forms.Application]::Exit()
})

$itemSpan.add_Click({ Invoke-SpanWindow -manual $true })

$itemExit.add_Click({
    $timer.Stop(); $trayIcon.Visible = $false
    $form.Close(); [System.Windows.Forms.Application]::Exit()
})

$form.add_FormClosing({
    param($sender, $e)
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) {
        $e.Cancel = $true
        $form.Hide()
        $trayIcon.ShowBalloonTip(1500, "Akimbo Minimized",
            "Running in System Tray. Right-click or double-click to control.", "Info")
    }
})

# ==============================================================================
# LAUNCH
# ==============================================================================
Add-Log "Akimbo Companion v1.2 initialized."
Add-Log "Monitoring active. Enable Akimbo in WoW; calibrate with /akimbo wizard."
$timer.Start()

[System.Windows.Forms.Application]::Run($form)
