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
    if (-Not (Test-Path $file)) {
        Write-Host "[!] TlauncherProfiles.json non trovato." -ForegroundColor Yellow
        return
    }

    $data = Get-Content $file -Raw | ConvertFrom-Json
    $accounts = $data.accounts.PSObject.Properties

    foreach ($acc in $accounts) {
        $info = $acc.Value
        if ($info.username -and $info.uuid) {
            $hasToken = $false
            if ($info.microsoftOAuthToken.accessToken) {
                $hasToken = $true
            } elseif ($info.microsoftOAuthToken.id_token) {
                $hasToken = $true
            }
            $premium = if ($hasToken) { '✅' } else { '❌' }

            Write-Host "[✓] Account: $($info.displayName) | UUID: $($info.uuid) | Tipo: $($info.type) | Premium: $premium" -ForegroundColor Green

            if ($info.microsoftOAuthToken.accessToken) {
                $claims = Decode-Jwt $info.microsoftOAuthToken.accessToken
                if ($claims) {
                    Write-Host "    → Microsoft access token claims:" -ForegroundColor Cyan
                    $claims | Format-Table -AutoSize
                }
            } elseif ($info.microsoftOAuthToken.id_token) {
                $claims = Decode-Jwt $info.microsoftOAuthToken.id_token
                if ($claims) {
                    Write-Host "    → Microsoft ID token claims:" -ForegroundColor Cyan
                    $claims | Format-Table -AutoSize
                }
            }
        }
    }
}

function Get-LauncherAccounts {
    $file = "$env:APPDATA\.minecraft\launcher_accounts.json"
    if (-Not (Test-Path $file)) {
        Write-Host "[!] launcher_accounts.json non trovato." -ForegroundColor Yellow
        return
    }

    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json
        $accounts = $data.accounts.PSObject.Properties

        if ($accounts.Count -eq 0) {
            Write-Host "[!] Nessun account trovato in launcher_accounts.json." -ForegroundColor Yellow
            return
        }

        Write-Host "[✓] Account trovati in launcher_accounts.json:" -ForegroundColor Cyan
        foreach ($acc in $accounts) {
            $info = $acc.Value
            $username = $info.username
            $uuid = $null
            if ($info.minecraftProfile) {
                $uuid = $info.minecraftProfile.id
                if ([string]::IsNullOrEmpty($uuid)) { $uuid = $null }
            }
            $type = if ($info.type) { $info.type } else { "N/A" }
            $token = if ($info.accessToken) { '✅' } else { '❌' }

            Write-Host "    → $username | UUID: $uuid | Tipo: $type | Token: $token" -ForegroundColor Green
        }
    } catch {
        Write-Host "[X] Errore durante la lettura di launcher_accounts.json." -ForegroundColor Red
    }
}

function Get-UsernameCache {
    $file = "$env:APPDATA\.minecraft\usernamecache.json"
    if (-Not (Test-Path $file)) {
        Write-Host "[!] usernamecache.json non trovato." -ForegroundColor Yellow
        return
    }

    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json

        if ($data.Count -eq 0) {
            Write-Host "[!] Nessun account trovato in usernamecache.json." -ForegroundColor Yellow
            return
        }

        Write-Host "[✓] Account trovati in usernamecache.json:" -ForegroundColor Cyan
        foreach ($entry in $data) {
            if ($entry.username -and $entry.uuid) {
                Write-Host "    → $($entry.username) | UUID: $($entry.uuid)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "[X] Errore durante la lettura di usernamecache.json." -ForegroundColor Red
    }
}

function Get-UserCache {
    $file = "$env:APPDATA\.minecraft\usercache.json"
    if (-Not (Test-Path $file)) {
        Write-Host "[!] usercache.json non trovato." -ForegroundColor Yellow
        return
    }

    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json

        if (-not $data) {
            Write-Host "[!] Nessun account trovato in usercache.json." -ForegroundColor Yellow
            return
        }

        Write-Host "[✓] Account trovati in usercache.json:" -ForegroundColor Cyan
        foreach ($entry in $data) {
            if ($entry.name -and $entry.uuid) {
                Write-Host "    → $($entry.name) | UUID: $($entry.uuid)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "[X] Errore durante la lettura di usercache.json." -ForegroundColor Red
    }
}

Get-TLauncherProfiles
Get-LauncherAccounts
Get-UsernameCache
Get-UserCache
