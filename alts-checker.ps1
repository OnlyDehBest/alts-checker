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

function Get-UsernameCacheAccounts {
    $tlauncherPath = "$env:APPDATA\.minecraft\usernamecache.json"
    if (-Not (Test-Path $tlauncherPath)) {
        Write-Host "[!] usernamecache.json non trovato." -ForegroundColor Yellow
        return
    }

    try {
        $data = Get-Content $tlauncherPath -Raw | ConvertFrom-Json

        if ($data.Count -eq 0) {
            Write-Host "[!] Nessun account trovato in usernamecache.json." -ForegroundColor Yellow
            return
        }

        Write-Host "[✓] Trovati $($data.Count) account in usernamecache.json:" -ForegroundColor Cyan
        foreach ($entry in $data) {
            if ($entry.username -and $entry.uuid) {
                Write-Host "    → $($entry.username) | UUID: $($entry.uuid)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "[X] Errore durante la lettura di usernamecache.json." -ForegroundColor Red
    }
}

function Get-UserCacheAccounts {
    $cachePath = "$env:APPDATA\.minecraft"
    if (-Not (Test-Path $cachePath)) { return }

    Get-ChildItem -Path $cachePath -Recurse -Include "*.json" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -like "usercache.json" } |
        ForEach-Object {
            try {
                $entries = Get-Content $_.FullName -Raw | ConvertFrom-Json
                $valid = $entries | Where { $_.name -and $_.uuid }
                if ($valid.Count -gt 0) {
                    Write-Host "[✓] Cache file: $($_.Name)" -ForegroundColor Magenta
                    foreach ($e in $valid) {
                        Write-Host "    → $($e.name) | UUID: $($e.uuid)" -ForegroundColor Magenta
                    }
                }
            } catch {}
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

        foreach ($acc in $accounts) {
            $info = $acc.Value
            $username = $info.username
            $uuid = $info.minecraftProfile.id

            if (-not $uuid -or $uuid.Trim() -eq '') {
                Write-Host "[X] UUID mancante o vuoto per l'account '$username'." -ForegroundColor Red
                continue
            }

            $hasToken = if ($info.accessToken) { '✅' } else { '❌' }

            Write-Host "[✓] Account: $username | UUID: $uuid | Tipo: $($info.type) | Token: $hasToken" -ForegroundColor Green
        }
    } catch {
        Write-Host "[X] Errore durante la lettura di launcher_accounts.json: $_" -ForegroundColor Red
    }
}

Get-TLauncherProfiles
Get-UsernameCacheAccounts
Get-UserCacheAccounts
Get-LauncherAccounts
