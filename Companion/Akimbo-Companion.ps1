# ==============================================================================
# Akimbo Companion: Multi-Monitor Desktop Controller & Background Watcher
# Native Windows GUI with System Tray, Auto-Spanning, and Addon Validation
# ==============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

. (Join-Path $PSScriptRoot 'Akimbo-Window.ps1')

# Theme Colors
$cBg       = [System.Drawing.Color]::FromArgb(18, 20, 24)       # Deep Obsidian
$cCard     = [System.Drawing.Color]::FromArgb(26, 29, 36)       # Dark Slate Card
$cBorder   = [System.Drawing.Color]::FromArgb(44, 49, 60)       # Border Outline
$cText     = [System.Drawing.Color]::FromArgb(235, 240, 248)    # Crisp Off-White
$cMuted    = [System.Drawing.Color]::FromArgb(135, 145, 160)    # Subdued Gray
$cCyan     = [System.Drawing.Color]::FromArgb(0, 204, 255)      # Akimbo Cyan
$cGreen    = [System.Drawing.Color]::FromArgb(0, 230, 118)      # Emerald Success
$cRed      = [System.Drawing.Color]::FromArgb(255, 82, 82)      # Crimson Alert
$cYellow   = [System.Drawing.Color]::FromArgb(255, 215, 64)     # Amber Warning

# Main Application Window
$form = New-Object System.Windows.Forms.Form
$form.Text = "Akimbo Dual Monitor Companion"
$form.Size = New-Object System.Drawing.Size(520, 560)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.BackColor = $cBg
$form.ForeColor = $cText

# Helper: Create Custom Button
function New-StyledButton {
    param($text, $x, $y, $w, $h, $bgColor, $textColor)
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $text
    $btn.Location = New-Object System.Drawing.Point($x, $y)
    $btn.Size = New-Object System.Drawing.Size($w, $h)
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderSize = 0
    $btn.BackColor = $bgColor
    $btn.ForeColor = $textColor
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    return $btn
}

# Header Banner
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "AKIMBO COMPANION"
$titleLabel.Location = New-Object System.Drawing.Point(20, 16)
$titleLabel.Size = New-Object System.Drawing.Size(460, 26)
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 14, [System.Drawing.FontStyle]::Bold)
$titleLabel.ForeColor = $cCyan
$form.Controls.Add($titleLabel)

$subLabel = New-Object System.Windows.Forms.Label
$subLabel.Text = "Dual-Monitor Multi-Display Controller for World of Warcraft"
$subLabel.Location = New-Object System.Drawing.Point(22, 42)
$subLabel.Size = New-Object System.Drawing.Size(460, 18)
$subLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$subLabel.ForeColor = $cMuted
$form.Controls.Add($subLabel)

# Status Group Card
$statusPanel = New-Object System.Windows.Forms.Panel
$statusPanel.Location = New-Object System.Drawing.Point(20, 68)
$statusPanel.Size = New-Object System.Drawing.Size(464, 110)
$statusPanel.BackColor = $cCard
$statusPanel.BorderStyle = "FixedSingle"
$form.Controls.Add($statusPanel)

$lblWowStatus = New-Object System.Windows.Forms.Label
$lblWowStatus.Text = "WoW Process: Checking..."
$lblWowStatus.Location = New-Object System.Drawing.Point(16, 12)
$lblWowStatus.Size = New-Object System.Drawing.Size(430, 20)
$lblWowStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblWowStatus.ForeColor = $cMuted
$statusPanel.Controls.Add($lblWowStatus)

$lblAddonStatus = New-Object System.Windows.Forms.Label
$lblAddonStatus.Text = "Akimbo Addon: Checking..."
$lblAddonStatus.Location = New-Object System.Drawing.Point(16, 36)
$lblAddonStatus.Size = New-Object System.Drawing.Size(430, 20)
$lblAddonStatus.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$lblAddonStatus.ForeColor = $cMuted
$statusPanel.Controls.Add($lblAddonStatus)

$lblDisplayInfo = New-Object System.Windows.Forms.Label
$lblDisplayInfo.Text = "Virtual Desktop: Checking..."
$lblDisplayInfo.Location = New-Object System.Drawing.Point(16, 60)
$lblDisplayInfo.Size = New-Object System.Drawing.Size(430, 20)
$lblDisplayInfo.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$lblDisplayInfo.ForeColor = $cMuted
$statusPanel.Controls.Add($lblDisplayInfo)

$lblAddonReason = New-Object System.Windows.Forms.Label
$lblAddonReason.Text = "Live addon state cannot be verified by the companion."
$lblAddonReason.Location = New-Object System.Drawing.Point(16, 82)
$lblAddonReason.Size = New-Object System.Drawing.Size(430, 18)
$lblAddonReason.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$lblAddonReason.ForeColor = $cYellow
$statusPanel.Controls.Add($lblAddonReason)

# Auto-Span Toggle Switch
$chkAutoSpan = New-Object System.Windows.Forms.CheckBox
$chkAutoSpan.Text = "Enable Automatic Spanning on Game Launch"
$chkAutoSpan.Location = New-Object System.Drawing.Point(22, 190)
$chkAutoSpan.Size = New-Object System.Drawing.Size(460, 24)
$chkAutoSpan.Font = New-Object System.Drawing.Font("Segoe UI", 9.5, [System.Drawing.FontStyle]::Bold)
$chkAutoSpan.ForeColor = $cText
$chkAutoSpan.Checked = $true
$form.Controls.Add($chkAutoSpan)

# Action Buttons
$btnSpanNow = New-StyledButton -text "Span WoW Window Now" -x 20 -y 224 -w 226 -h 38 -bgColor ([System.Drawing.Color]::FromArgb(0, 130, 200)) -textColor [System.Drawing.Color]::White
$form.Controls.Add($btnSpanNow)

$btnToggleWatch = New-StyledButton -text "Pause Monitoring" -x 258 -y 224 -w 226 -h 38 -bgColor ([System.Drawing.Color]::FromArgb(50, 56, 70)) -textColor $cText
$form.Controls.Add($btnToggleWatch)

# Activity Log Header
$logHeader = New-Object System.Windows.Forms.Label
$logHeader.Text = "ACTIVITY LOG"
$logHeader.Location = New-Object System.Drawing.Point(22, 274)
$logHeader.Size = New-Object System.Drawing.Size(460, 18)
$logHeader.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$logHeader.ForeColor = $cMuted
$form.Controls.Add($logHeader)

# Activity Log ListBox
$logBox = New-Object System.Windows.Forms.ListBox
$logBox.Location = New-Object System.Drawing.Point(20, 296)
$logBox.Size = New-Object System.Drawing.Size(464, 160)
$logBox.BackColor = [System.Drawing.Color]::FromArgb(14, 15, 18)
$logBox.ForeColor = [System.Drawing.Color]::FromArgb(200, 210, 225)
$logBox.BorderStyle = "FixedSingle"
$logBox.Font = New-Object System.Drawing.Font("Consolas", 8.5)
$form.Controls.Add($logBox)

# Bottom Status Footer
$btnMinimize = New-StyledButton -text "Minimize to Tray" -x 20 -y 468 -w 150 -h 32 -bgColor ([System.Drawing.Color]::FromArgb(35, 40, 50)) -textColor $cMuted
$form.Controls.Add($btnMinimize)

$btnExit = New-StyledButton -text "Exit Companion" -x 334 -y 468 -w 150 -h 32 -bgColor ([System.Drawing.Color]::FromArgb(40, 25, 25)) -textColor $cRed
$form.Controls.Add($btnExit)

# Logging Helper
function Add-Log {
    param($msg, $color)
    $time = (Get-Date).ToString("HH:mm:ss")
    $entry = "[$time] $msg"
    $logBox.Items.Insert(0, $entry)
    while ($logBox.Items.Count -gt 100) {
        $logBox.Items.RemoveAt($logBox.Items.Count - 1)
    }
}

# ==============================================================================
# System Tray Icon & Context Menu
# ==============================================================================
$trayIcon = New-Object System.Windows.Forms.NotifyIcon
$trayIcon.Text = "Akimbo Companion"
$trayIcon.Visible = $true

# Generate a clean icon programmatically
$bmp = New-Object System.Drawing.Bitmap 16, 16
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.Clear([System.Drawing.Color]::FromArgb(0, 204, 255))
$hIcon = $bmp.GetHicon()
$trayIcon.Icon = [System.Drawing.Icon]::FromHandle($hIcon)

$trayMenu = New-Object System.Windows.Forms.ContextMenuStrip
$itemOpen = $trayMenu.Items.Add("Open Dashboard")
$trayMenu.Items.Add("-")
$itemSpan = $trayMenu.Items.Add("Span WoW Now")
$itemAuto = $trayMenu.Items.Add("Auto-Span Enabled")
$itemAuto.Checked = $true
$trayMenu.Items.Add("-")
$itemExit = $trayMenu.Items.Add("Exit")

$trayIcon.ContextMenuStrip = $trayMenu

$trayIcon.add_DoubleClick({
    $form.Show()
    $form.WindowState = "Normal"
    $form.Activate()
})

$itemOpen.add_Click({
    $form.Show()
    $form.WindowState = "Normal"
    $form.Activate()
})

$itemAuto.add_Click({
    $chkAutoSpan.Checked = -not $chkAutoSpan.Checked
    $itemAuto.Checked = $chkAutoSpan.Checked
})

# ==============================================================================
# Addon Validation & Process Inspection Logic
# ==============================================================================
function Invoke-SpanWindow {
    param([bool]$manual = $false)
    try {
        $bounds = Invoke-AkimboSpan (Get-WoWProcess)
        Add-Log "Spanned $($bounds.Width)x$($bounds.Height). Calibrate with /akimbo wizard."
        $trayIcon.ShowBalloonTip(3000, "Akimbo Spanned", "Window spanned. Confirm Akimbo is enabled; use /akimbo wizard to calibrate.", "Info")
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
# Background Watcher Engine (Timer)
# ==============================================================================
$isMonitoring = $true
$spannedPids = @{}
$retryAfter = @{}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 2000 # Poll every 2 seconds

$timer.add_Tick({
    try {
        $vs = Get-AkimboDesktopBounds
        $lblDisplayInfo.Text = "Virtual Desktop: $($vs.Width) x $($vs.Height) px (X: $($vs.X), Y: $($vs.Y))"
    } catch { $lblDisplayInfo.Text = "Virtual Desktop: physical coordinates unavailable" }

    $proc = Get-WoWProcess

    if ($proc) {
        $lblWowStatus.Text = "WoW Process: RUNNING ($($proc.ProcessName) - PID: $($proc.Id))"
        $lblWowStatus.ForeColor = $cGreen

        $status = Test-AkimboAddonStatus -proc $proc

        if ($status.Installed) {
            $lblAddonStatus.Text = "Akimbo Addon: INSTALLED (enable in WoW)"
            $lblAddonStatus.ForeColor = $cGreen
            $lblAddonReason.Text = "Confirm Akimbo is enabled in the current WoW session."
        } else {
            $lblAddonStatus.Text = "Akimbo Addon: NOT VERIFIED"
            $lblAddonStatus.ForeColor = $cRed
            $lblAddonReason.Text = $status.Reason
        }

        # Auto-Spanning Trigger
        if ($isMonitoring -and $chkAutoSpan.Checked -and $status.Installed) {
            if (-not $spannedPids.ContainsKey($proc.Id) -and
                (-not $retryAfter.ContainsKey($proc.Id) -or (Get-Date) -ge $retryAfter[$proc.Id])) {
                Add-Log "New WoW launch detected (PID: $($proc.Id)). Preparing auto-span..."
                $retryAfter[$proc.Id] = (Get-Date).AddSeconds(10)
                if (Invoke-SpanWindow -manual $false) {
                    $spannedPids[$proc.Id] = $true
                }
            }
        }
    } else {
        $lblWowStatus.Text = "WoW Process: Run exactly one client"
        $lblWowStatus.ForeColor = $cMuted
        $lblAddonStatus.Text = "Akimbo Addon: Waiting for WoW..."
        $lblAddonStatus.ForeColor = $cMuted
        $lblAddonReason.Text = ""
    }

    # Clean dead PIDs
    $keys = @($spannedPids.Keys)
    foreach ($k in $keys) {
        $p = Get-Process -Id $k -ErrorAction SilentlyContinue
        if (-not $p) {
            $spannedPids.Remove($k)
            $retryAfter.Remove($k)
            Add-Log "WoW process (PID: $k) closed."
        }
    }
})

# UI Event Handlers
$btnSpanNow.add_Click({
    Invoke-SpanWindow -manual $true
})

$btnToggleWatch.add_Click({
    $isMonitoring = -not $isMonitoring
    if ($isMonitoring) {
        $btnToggleWatch.Text = "Pause Monitoring"
        $btnToggleWatch.BackColor = [System.Drawing.Color]::FromArgb(50, 56, 70)
        Add-Log "Background auto-watcher resumed."
    } else {
        $btnToggleWatch.Text = "Resume Monitoring"
        $btnToggleWatch.BackColor = [System.Drawing.Color]::FromArgb(90, 70, 20)
        Add-Log "Background auto-watcher PAUSED by user."
    }
})

$chkAutoSpan.add_CheckedChanged({
    $itemAuto.Checked = $chkAutoSpan.Checked
    Add-Log "Auto-Span on launch set to: $($chkAutoSpan.Checked)"
})

$btnMinimize.add_Click({
    $form.Hide()
    $trayIcon.ShowBalloonTip(2000, "Akimbo Running in Tray", "Akimbo Companion is monitoring in the background. Double-click the tray icon to restore.", "Info")
})

$btnExit.add_Click({
    $timer.Stop()
    $trayIcon.Visible = $false
    $form.Close()
    [System.Windows.Forms.Application]::Exit()
})

$itemSpan.add_Click({
    Invoke-SpanWindow -manual $true
})

$itemExit.add_Click({
    $timer.Stop()
    $trayIcon.Visible = $false
    $form.Close()
    [System.Windows.Forms.Application]::Exit()
})

# Intercept Form X button to minimize to tray instead of quitting
$form.add_FormClosing({
    param($sender, $e)
    if ($e.CloseReason -eq [System.Windows.Forms.CloseReason]::UserClosing) {
        $e.Cancel = $true
        $form.Hide()
        $trayIcon.ShowBalloonTip(1500, "Akimbo Minimized", "Running in System Tray. Right-click or double-click to control.", "Info")
    }
})

# Start application
Add-Log "Akimbo Companion v1.1 initialized."
Add-Log "Monitoring. Enable Akimbo in WoW; calibrate with /akimbo wizard."
$timer.Start()

[System.Windows.Forms.Application]::Run($form)
