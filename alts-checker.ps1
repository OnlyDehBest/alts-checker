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

    Write-Host "[✓] Account trovati in TlauncherProfiles.json:" -ForegroundColor Cyan

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

            Write-Host "    → $($info.displayName) | UUID: $($info.uuid) | Tipo: $($info.type) | Premium: $premium" -ForegroundColor Green

            if ($info.microsoftOAuthToken.accessToken) {
                $claims = Decode-Jwt $info.microsoftOAuthToken.accessToken
                if ($claims) {
                    Write-Host "       → Microsoft access token claims:" -ForegroundColor Cyan
                    $claims | Format-Table -AutoSize
                }
            } elseif ($info.microsoftOAuthToken.id_token) {
                $claims = Decode-Jwt $info.microsoftOAuthToken.id_token
                if ($claims) {
                    Write-Host "       → Microsoft ID token claims:" -ForegroundColor Cyan
                    $claims | Format-Table -AutoSize
                }
            }
        }
    }
}

function Get-UsernameCacheAccounts {
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
        Write-Host "[X] Errore nella lettura di usernamecache.json." -ForegroundColor Red
    }
}

function Get-LauncherAccounts {
    $file = "$env:APPDATA\.minecraft\launcher_accounts.json"
    if (-Not (Test-Path $file)) {
        Write-Host "[!] launcher_accounts.json non trovato." -ForegroundColor Yellow
        return
    }

    try {
        $json = Get-Content $file -Raw | ConvertFrom-Json
        $accounts = $json.accounts.PSObject.Properties

        Write-Host "[✓] Account trovati in launcher_accounts.json:" -ForegroundColor Cyan

        foreach ($entry in $accounts) {
            $acc = $entry.Value
            $username = $acc.username
            $type = $acc.type
            $token = $acc.accessToken
            $minecraftProfile = $acc.minecraftProfile
            $nickname = if ($minecraftProfile.name) { $minecraftProfile.name } else { "N/A" }
            $uuid = if ($minecraftProfile.id) { $minecraftProfile.id } else { "N/A" }

            $premium = if ($token -ne "") { "✅" } else { "❌" }

            Write-Host "    → Username launcher: $username | Minecraft: $nickname | UUID: $uuid | Tipo: $type | Token: $premium" -ForegroundColor Green

            if ($token -ne "") {
                $claims = Decode-Jwt $token
                if ($claims) {
                    Write-Host "       → Token claims:" -ForegroundColor Cyan
                    $claims | Format-Table -AutoSize
                }
            }
        }
    } catch {
        Write-Host "[X] Errore nella lettura di launcher_accounts.json." -ForegroundColor Red
    }
}

function Get-UserCacheAccounts {
    $path = "$env:APPDATA\.minecraft\usercache.json"
    if (-Not (Test-Path $path)) {
        Write-Host "[!] usercache.json non trovato." -ForegroundColor Yellow
        return
    }

    try {
        $entries = Get-Content $path -Raw | ConvertFrom-Json
        $valid = $entries | Where-Object { $_.name -and $_.uuid }

        if ($valid.Count -gt 0) {
            Write-Host "[✓] Account trovati in usercache.json:" -ForegroundColor Magenta
            foreach ($e in $valid) {
                Write-Host "    → $($e.name) | UUID: $($e.uuid)" -ForegroundColor Magenta
            }
        } else {
            Write-Host "[!] Nessun account valido trovato in usercache.json." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[X] Errore nella lettura di usercache.json." -ForegroundColor Red
    }
}

Get-TLauncherProfiles
Get-UsernameCacheAccounts
Get-LauncherAccounts
Get-UserCacheAccounts
