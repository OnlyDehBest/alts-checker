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
    $path = Join-Path $env:APPDATA '.minecraft\TlauncherProfiles.json'
    Write-Host "`n══════ TLAUNCHER PROFILES ══════" -ForegroundColor Magenta
    if (-not (Test-Path $path)) {
        Write-Host "[!] Profile file not found." -ForegroundColor Yellow; return
    }
    $data = Get-Content $path -Raw | ConvertFrom-Json
    foreach ($acc in $data.accounts.PSObject.Properties) {
        $info = $acc.Value
        if ($info.username -and $info.uuid) {
            if ($info.microsoftOAuthToken.accessToken) {
                $token = $info.microsoftOAuthToken.accessToken; $label = "Access Token"
            } elseif ($info.microsoftOAuthToken.id_token) {
                $token = $info.microsoftOAuthToken.id_token; $label = "ID Token"
            } else { $token = $null; $label = "" }

            $premium = if ($token) { '✅' } else { '❌' }
            Write-Host "✔ $($info.displayName) | UUID: $($info.uuid) | Type: $($info.type) | Premium: $premium" -ForegroundColor Green

            if ($token) {
                $claims = Decode-Jwt $token
                if ($claims) {
                    Write-Host "   → $label claims:" -ForegroundColor Cyan
                    $claims | Format-Table -AutoSize
                }
            }
        }
    }
}

function Get-LauncherAccounts {
    $path = Join-Path $env:APPDATA '.minecraft\launcher_accounts.json'
    Write-Host "`n══════ LAUNCHER ACCOUNTS ══════" -ForegroundColor Magenta
    if (-not (Test-Path $path)) {
        Write-Host "[!] launcher_accounts.json not found." -ForegroundColor Yellow; return
    }
    try {
        $data = Get-Content $path -Raw | ConvertFrom-Json
        if (-not $data.accounts) {
            Write-Host "[!] No accounts in launcher_accounts.json." -ForegroundColor Yellow; return
        }
        foreach ($acc in $data.accounts.PSObject.Properties) {
            $info = $acc.Value
            $uuid = $null
            if ($info.minecraftProfile -and $info.minecraftProfile.id) {
                $uuid = $info.minecraftProfile.id
            }
            $type = if ($info.type) { $info.type } else { "N/A" }
            $token = if ($info.accessToken) { '✅' } else { '❌' }
            Write-Host "→ $($info.username) | UUID: $uuid | Type: $type | Token: $token" -ForegroundColor Green
        }
    } catch {
        Write-Host "[X] Error reading launcher_accounts.json." -ForegroundColor Red
    }
}

function Get-UsernameCache {
    $path = Join-Path $env:APPDATA '.minecraft\usernamecache.json'
    Write-Host "`n══════ USERNAME CACHE ══════" -ForegroundColor Magenta
    if (-not (Test-Path $path)) {
        Write-Host "[!] usernamecache.json not found." -ForegroundColor Yellow; return
    }
    try {
        $cache = Get-Content $path -Raw | ConvertFrom-Json
        if (-not $cache) {
            Write-Host "[!] Empty usernamecache.json." -ForegroundColor Yellow; return
        }
        foreach ($entry in $cache) {
            if ($entry.username -and $entry.uuid) {
                Write-Host "→ $($entry.username) | UUID: $($entry.uuid)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "[X] Error reading usernamecache.json." -ForegroundColor Red
    }
}

function Get-UserCache {
    $path = Join-Path $env:APPDATA '.minecraft\usercache.json'
    Write-Host "`n══════ USER CACHE ══════" -ForegroundColor Magenta
    if (-not (Test-Path $path)) {
        Write-Host "[!] usercache.json not found." -ForegroundColor Yellow; return
    }
    try {
        $cache = Get-Content $path -Raw | ConvertFrom-Json
        if (-not $cache) {
            Write-Host "[!] Empty usercache.json." -ForegroundColor Yellow; return
        }
        foreach ($entry in $cache) {
            if ($entry.name -and $entry.uuid) {
                Write-Host "→ $($entry.name) | UUID: $($entry.uuid)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "[X] Error reading usercache.json." -ForegroundColor Red
    }
}

Get-TLauncherProfiles
Get-LauncherAccounts
Get-UsernameCache
Get-UserCache
