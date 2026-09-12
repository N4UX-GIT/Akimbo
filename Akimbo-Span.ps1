param([switch]$Watch)
. (Join-Path $PSScriptRoot 'Companion\Akimbo-Window.ps1')

Write-Host 'Akimbo: borderless window spanning'
Write-Host 'Enable Akimbo in WoW and select Windowed mode. Run only one WoW client.'
Write-Host 'After spanning, use /akimbo wizard to calibrate; existing settings are reused.'
$completed = @{}
$lastMessage = ''
do {
    $proc = Get-WoWProcess
    if ($proc -and -not $completed.ContainsKey($proc.Id)) {
        try {
            $bounds = Invoke-AkimboSpan $proc
            Write-Host "Spanned $($bounds.Width)x$($bounds.Height) at ($($bounds.X), $($bounds.Y))."
            Write-Host 'Confirm Akimbo is enabled. Use /akimbo wizard for seam, HUD and bottom alignment.'
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
