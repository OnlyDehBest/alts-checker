function Print-AnimatedLogo {
    Clear-Host
    $padding = " " * 10
    Write-Host -NoNewline ($padding)
    Write-Host -ForegroundColor Cyan @"
                              
   __ _| | |_ ___        ___| |__   ___  ___| | _____ _ __ 
  / _` | | __/ __|_____ / __| '_ \ / _ \/ __| |/ / _ \ '__|
 | (_| | | |_\__ \_____| (__| | | |  __/ (__|   <  __/ |   
  \__,_|_|\__|___/      \___|_| |_|\___|\___|_|\_\___|_|
"@
    Start-Sleep -Milliseconds 500
}

function Decode-Jwt {
    param([string]$jwt)

    $parts = $jwt -split '\.'
    if ($parts.Count -ne 3) { return }

    $payload = $parts[1].Replace('-', '+').Replace('_', '/')
    switch ($payload.Length % 4) {
        2 { $payload += '==' }
        3 { $payload += '=' }
    }

    try {
        $bytes = [Convert]::FromBase64String($payload)
        return ([Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Get-TLauncherProfiles {
    $file = "$env:APPDATA\.minecraft\TlauncherProfiles.json"
    if (-not (Test-Path $file)) {
        Write-Host "`n[TLauncherProfiles.json not found]" -ForegroundColor Gray
        return
    }

    $data = Get-Content $file -Raw | ConvertFrom-Json
    Write-Host "`n--- TLauncher Profiles ---`n" -ForegroundColor Cyan
    foreach ($acc in $data.accounts.PSObject.Properties) {
        $info = $acc.Value
        if ($info.username -and $info.uuid) {
            $token = $null
            if ($info.microsoftOAuthToken.accessToken) { $token = $info.microsoftOAuthToken.accessToken }
            elseif ($info.microsoftOAuthToken.id_token) { $token = $info.microsoftOAuthToken.id_token }

            $premium = if ($token) { 'yes' } else { 'no' }

            Write-Host ("DisplayName:`t{0}" -f $info.displayName) -ForegroundColor Green
            Write-Host ("UUID:`t`t{0}" -f $info.uuid) -ForegroundColor DarkGreen
            Write-Host ("Type:`t`t{0}" -f $info.type) -ForegroundColor DarkGreen
            Write-Host ("Premium:`t{0}`n" -f $premium) -ForegroundColor Green

            if ($token) {
                $claims = Decode-Jwt $token
                if ($claims) { $claims | Format-Table -AutoSize }
                Write-Host ""
            }
        }
    }
}

function Get-LauncherAccounts {
    $file = "$env:APPDATA\.minecraft\launcher_accounts.json"
    if (-not (Test-Path $file)) {
        Write-Host "`n[launcher_accounts.json not found]" -ForegroundColor Gray
        return
    }

    Write-Host "`n--- Launcher Accounts ---`n" -ForegroundColor Cyan
    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json
        if (-not $data.accounts) {
            Write-Host "[No accounts found]" -ForegroundColor Gray
            return
        }

        foreach ($acc in $data.accounts.PSObject.Properties) {
            $info = $acc.Value
            $uuid = if ($info.minecraftProfile -and $info.minecraftProfile.id) { $info.minecraftProfile.id } else { "N/A" }
            $type = if ($info.type) { $info.type } else { "N/A" }
            $token = if ($info.accessToken) { 'yes' } else { 'no' }

            Write-Host ("Username:`t{0}" -f $info.username) -ForegroundColor Green
            Write-Host ("UUID:`t`t{0}" -f $uuid) -ForegroundColor DarkGreen
            Write-Host ("Type:`t`t{0}" -f $type) -ForegroundColor DarkGreen
            Write-Host ("Token:`t{0}`n" -f $token) -ForegroundColor Green
        }
    }
    catch {
        Write-Host "`n[Error reading launcher_accounts.json]" -ForegroundColor Red
    }
}

function Get-UsernameCache {
    $file = "$env:APPDATA\.minecraft\usernamecache.json"
    if (-not (Test-Path $file)) {
        Write-Host "`n[usernamecache.json not found]" -ForegroundColor Gray
        return
    }

    Write-Host "`n--- Username Cache ---`n" -ForegroundColor Cyan
    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json
        if (-not $data) { Write-Host "[usernamecache.json empty]" -ForegroundColor Gray; return }

        foreach ($entry in $data) {
            if ($entry.username -and $entry.uuid) {
                Write-Host ("Username:`t{0}" -f $entry.username) -ForegroundColor Green
                Write-Host ("UUID:`t`t{0}`n" -f $entry.uuid) -ForegroundColor DarkGreen
            }
        }
    } catch {
        Write-Host "`n[Error reading usernamecache.json]" -ForegroundColor Red
    }
}

function Get-UserCache {
    $file = "$env:APPDATA\.minecraft\usercache.json"
    if (-not (Test-Path $file)) {
        Write-Host "`n[usercache.json not found]" -ForegroundColor Gray
        return
    }

    Write-Host "`n--- User Cache ---`n" -ForegroundColor Cyan
    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json
        if (-not $data) { Write-Host "[usercache.json empty]" -ForegroundColor Gray; return }

        foreach ($entry in $data) {
            if ($entry.name -and $entry.uuid) {
                Write-Host ("Name:`t{0}" -f $entry.name) -ForegroundColor Green
                Write-Host ("UUID:`t{0}`n" -f $entry.uuid) -ForegroundColor DarkGreen
            }
        }
    } catch {
        Write-Host "`n[Error reading usercache.json]" -ForegroundColor Red
    }
}

function Print-Menu {
    Clear-Host
    Print-AnimatedLogo
    Write-Host ""
    Write-Host "                                       ------------------------------" -ForegroundColor Cyan
    Write-Host "                                              ALTS-CHECKER TOOL        " -ForegroundColor Cyan
    Write-Host "                                       ------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "                                    1. Open Log Folders" -ForegroundColor Green
    Write-Host "                                    2. Search Deleted Logs" -ForegroundColor Green
    Write-Host "                                    3. Show Minecraft Accounts" -ForegroundColor Green
    Write-Host "                                    4. Exit" -ForegroundColor Green
    Write-Host ""
    $choice = Read-Host "                                    Select an option"
    return $choice
}

while ($true) {
    $choice = Print-Menu

    switch ($choice) {
        "1" {
            Clear-Host
            Write-Host "Opening log folders..." -ForegroundColor Green
            Start-Process -FilePath "$env:APPDATA\.minecraft\logs"
            Start-Process -FilePath "$env:APPDATA\.minecraft\logs\blclient\minecraft\" -ErrorAction SilentlyContinue
            Start-Process -FilePath "$env:USERPROFILE\.lunarclient\offline\1.8\logs" -ErrorAction SilentlyContinue
            Start-Process -FilePath "$env:USERPROFILE\.lunarclient\offline\multiver\logs" -ErrorAction SilentlyContinue
            Pause
        }
        "2" {
            Clear-Host
            Write-Host "Searching for deleted logs..." -ForegroundColor Green
            Set-Location C:\
            fsutil usn readjournal C: csv | 
                findstr /i /C:"0x80000200" | 
                findstr /i /C:"latest.log" /i /C:".log.gz" /i /C:"launcher_profiles.json" /i /C:"usernamecache.json" /i /C:"usercache.json" /i /C:"shig.inima" /i /C:"launcher_accounts.json" > logs.txt
            Start-Process -FilePath "notepad.exe" -ArgumentList "logs.txt"
            Pause
        }
        "3" {
            Clear-Host
            Write-Host "Showing Minecraft accounts..." -ForegroundColor Green
            Get-TLauncherProfiles
            Get-LauncherAccounts
            Get-UsernameCache
            Get-UserCache
            Pause
        }
        "4" {
            Write-Host "Exiting..." -ForegroundColor Cyan
            break
        }
        default {
            Write-Host "Invalid option, please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}
