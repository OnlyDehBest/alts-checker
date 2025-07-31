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
        Write-Host "TlauncherProfiles.json not found" -ForegroundColor Yellow
        return
    }

    $data = Get-Content $file -Raw | ConvertFrom-Json
    foreach ($acc in $data.accounts.PSObject.Properties) {
        $info = $acc.Value
        if ($info.username -and $info.uuid) {
            $token = $null
            if ($info.microsoftOAuthToken.accessToken) {
                $token = $info.microsoftOAuthToken.accessToken
            } elseif ($info.microsoftOAuthToken.id_token) {
                $token = $info.microsoftOAuthToken.id_token
            }

            $premium = if ($token) { 'yes' } else { 'no' }
            Write-Host "$($info.displayName) | UUID: $($info.uuid) | Type: $($info.type) | Premium: $premium" -ForegroundColor Green

            if ($token) {
                $claims = Decode-Jwt $token
                if ($claims) {
                    $claims | Format-Table -AutoSize
                }
            }
        }
    }
}

function Get-LauncherAccounts {
    $file = "$env:APPDATA\.minecraft\launcher_accounts.json"
    if (-not (Test-Path $file)) {
        Write-Host "launcher_accounts.json not found" -ForegroundColor Yellow
        return
    }

    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json
        if (-not $data.accounts) {
            Write-Host "No accounts found in launcher_accounts.json" -ForegroundColor Yellow
            return
        }

        foreach ($acc in $data.accounts.PSObject.Properties) {
            $info = $acc.Value
            $uuid = $null
            if ($info.minecraftProfile -and $info.minecraftProfile.id) {
                $uuid = $info.minecraftProfile.id
            }
            $type = if ($info.type) { $info.type } else { "N/A" }
            $token = if ($info.accessToken) { 'yes' } else { 'no' }
            Write-Host "$($info.username) | UUID: $uuid | Type: $type | Token: $token" -ForegroundColor Green
        }
    } catch {
        Write-Host "Error reading launcher_accounts.json" -ForegroundColor Red
    }
}

function Get-UsernameCache {
    $file = "$env:APPDATA\.minecraft\usernamecache.json"
    if (-not (Test-Path $file)) {
        Write-Host "usernamecache.json not found" -ForegroundColor Yellow
        return
    }

    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json
        if (-not $data) {
            Write-Host "Empty usernamecache.json" -ForegroundColor Yellow
            return
        }

        foreach ($entry in $data) {
            if ($entry.username -and $entry.uuid) {
                Write-Host "$($entry.username) | UUID: $($entry.uuid)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Error reading usernamecache.json" -ForegroundColor Red
    }
}

function Get-UserCache {
    $file = "$env:APPDATA\.minecraft\usercache.json"
    if (-not (Test-Path $file)) {
        Write-Host "usercache.json not found" -ForegroundColor Yellow
        return
    }

    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json
        if (-not $data) {
            Write-Host "Empty usercache.json" -ForegroundColor Yellow
            return
        }

        foreach ($entry in $data) {
            if ($entry.name -and $entry.uuid) {
                Write-Host "$($entry.name) | UUID: $($entry.uuid)" -ForegroundColor Green
            }
        }
    } catch {
        Write-Host "Error reading usercache.json" -ForegroundColor Red
    }
}

Get-TLauncherProfiles
Get-LauncherAccounts
Get-UsernameCache
Get-UserCache
