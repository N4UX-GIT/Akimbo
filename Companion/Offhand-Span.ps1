param([switch]$Watch)
. (Join-Path $PSScriptRoot 'Offhand-Window.ps1')

Write-Host 'Offhand: borderless window spanning'
Write-Host 'Enable Offhand in WoW and select Windowed mode. Run only one WoW client.'
Write-Host 'After spanning, use /offhand wizard to calibrate; existing settings are reused.'
$completed = @{}
$lastMessage = ''
do {
    $proc = Get-WoWProcess
    if ($proc -and -not $completed.ContainsKey($proc.Id)) {
        try {
            $bounds = Invoke-OffhandSpan $proc
            Write-Host "Spanned $($bounds.Width)x$($bounds.Height) at ($($bounds.X), $($bounds.Y))."
            Write-Host 'Confirm Offhand is enabled. Use /offhand wizard for seam, HUD and bottom alignment.'
            $completed[$proc.Id] = $true
            $lastMessage = ''
        } catch {
            if ($lastMessage -ne $_.Exception.Message) { Write-Warning $_.Exception.Message }
            $lastMessage = $_.Exception.Message
            if (-not $Watch) { exit 1 }
        }
    } elseif (-not $proc) {
        $message = 'Waiting for exactly one running WoW client.'
        if ($lastMessage -ne $message) { Write-Host $message; $lastMessage = $message }
        if (-not $Watch) { exit 1 }
    }
    foreach ($key in @($completed.Keys)) {
        if (-not (Get-Process -Id $key -ErrorAction SilentlyContinue)) { $completed.Remove($key) }
    }
    if ($Watch) { Start-Sleep -Seconds 2 }
} while ($Watch)
