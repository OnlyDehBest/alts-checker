function Decode-Jwt {
    param([string]$jwt)

    $parts = $jwt -split '\.'
    if ($parts.Count -ne 3) { return }

    $payload = $parts[1].Replace('-', '+').Replace('_', '/')
    switch ($payload.Length % 4) {
        2 { $payload += '==' }
        3 { $payload += '=' }
        default {}
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
    Write-Host "`n───────────── TLAUNCHER PROFILES ─────────────" -ForegroundColor Magenta

    if (-not (Test-Path $file)) {
        Write-Host "[!] File not found: TlauncherProfiles.json" -ForegroundColor Yellow
        return
    }

    $data = Get-Content $file -Raw | ConvertFrom-Json
    $accounts = $data.accounts.PSObject.Properties

    foreach ($acc in $accounts) {
        $info = $acc.Value
        if ($info.username -and $info.uuid) {
            $hasToken = $false
            if ($info.microsoftOAuthToken.accessToken -or $info.microsoftOAuthToken.id_token) {
                $hasToken = $true
            }

            $premium = if ($hasToken) { '✅' } else { '❌' }

            Write-Host "✔ Account: $($info.displayName) | UUID: $($info.uuid) | Type: $($info.type) | Premium: $premium" -ForegroundColor Green

            $token = $info.microsoftOAuthToken.accessToken ?? $info.microsoftOAuthToken.id_token
            $label = if ($info.microsoftOAuthToken.accessToken) { "Microsoft access token" } else { "Microsoft ID token" }

            if ($token) {
                $claims = Decode-Jwt $token
                if ($claims) {
                    Write-Host "    → $label claims:" -ForegroundColor Cyan
                    $claims | Format-Table -AutoSize
                }
            }
        }
    }
}

function Get-LauncherAccounts {
    $file = "$env:APPDATA\.minecraft\launcher_accounts.json"
    Write-Host "`n───────────── OFFICIAL LAUNCHER ACCOUNTS ─────────────" -ForegroundColor Magenta

    if (-not (Test-Path $file)) {
        Write-Host "[!] File not found: launcher_accounts.json" -ForegroundColor Yellow
        return
    }

    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json
        $accounts = $data.accounts.PSObject.Properties

        if ($accounts.Count -eq 0) {
            Write-Host "[!] No accounts found in launcher_accounts.json" -ForegroundColor Yellow
            return
        }

        foreach ($acc in $accounts) {
            $info = $acc.Value
            $uuid = $info.minecraftProfile?.id
            $type = $info.type ?? "N/A"
            $token = if ($info.accessToken) { '✅' } else { '❌' }

            Write-Host "→ $($info.username) | UUID: $uuid | Type: $type | Token: $token" -ForegroundColor Green
        }
    } catch {
        Write-Host "[X] Failed to read launcher_accounts.json" -ForegroundColor Red
    }
}

function Get-UsernameCache {
    $file = "$env:APPDATA\.minecraft\usernamecache.json"
    Write-Host "`n───────────── USERNAME CACHE ─────────────" -ForegroundColor Magenta

    if (-not (Test-Path $file)) {
        Write-Host "[!] File not found: usernamecache.json" -ForegroundColor Yellow
        return
    }

    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json

        if ($data.Count -eq 0) {
            Write-Host "[!] No entries found in usernamecache.json" -ForegroundColor Yellow
            return
        }

        foreach ($entry in $data) {
            if ($entry.username -and $entry.uuid) {
                Write-Host "→ $($entry.username) | UUID: $($entry.uuid)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "[X] Failed to read usernamecache.json" -ForegroundColor Red
    }
}

function Get-UserCache {
    $file = "$env:APPDATA\.minecraft\usercache.json"
    Write-Host "`n───────────── USER CACHE ─────────────" -ForegroundColor Magenta

    if (-not (Test-Path $file)) {
        Write-Host "[!] File not found: usercache.json" -ForegroundColor Yellow
        return
    }

    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json

        if (-not $data) {
            Write-Host "[!] No entries found in usercache.json" -ForegroundColor Yellow
            return
        }

        foreach ($entry in $data) {
            if ($entry.name -and $entry.uuid) {
                Write-Host "→ $($entry.name) | UUID: $($entry.uuid)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "[X] Failed to read usercache.json" -ForegroundColor Red
    }
}

Get-TLauncherProfiles
Get-LauncherAccounts
Get-UsernameCache
Get-UserCache
