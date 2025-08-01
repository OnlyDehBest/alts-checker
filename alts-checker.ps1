$script:foundAccounts = @()
$script:reportData = @{}

function Print-AnimatedLogo {
    Clear-Host
    $width = $Host.UI.RawUI.BufferSize.Width

    $logoLines = @(
        "   __ _| | |_ ___        ___| |__   ___  ___| | _____ _ __",
        "  / _` | | __/ __|_____ / __| '_ \ / _ \/ __| |/ / _ \ '__|",
        " | (_| | | |_\__ \_____| (__| | | |  __/ (__|   <  __/ |   ",
        "  \__,_|_|\__|___/      \___|_| |_|\___|\___|_|\_\___|_|   ",
        "",
        "ENHANCED ALTS-CHECKER TOOL v2.0"
    )

    foreach ($line in $logoLines) {
        $padding = [Math]::Max(0, [int](($width - $line.Length) / 2))
        Write-Host (" " * $padding + $line) -ForegroundColor Red
    }
    Start-Sleep -Milliseconds 500
}

function Decode-Jwt {
    param([string]$jwt)

    $parts = $jwt -split '\.'
    if ($parts.Count -ne 3) { return $null }

    $payload = $parts[1].Replace('-', '+').Replace('_', '/')
    switch ($payload.Length % 4) {
        2 { $payload += '==' }
        3 { $payload += '=' }
    }

    try {
        $bytes = [Convert]::FromBase64String($payload)
        $decoded = [Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json
        
        if ($decoded.exp) {
            $expiry = [DateTimeOffset]::FromUnixTimeSeconds($decoded.exp).DateTime
            $decoded | Add-Member -NotePropertyName "ExpiryDate" -NotePropertyValue $expiry
            $decoded | Add-Member -NotePropertyName "IsExpired" -NotePropertyValue ($expiry -lt (Get-Date))
        }
        
        return $decoded
    } catch {
        return $null
    }
}

function Add-AccountToReport {
    param(
        [string]$Source,
        [string]$Username,
        [string]$UUID,
        [string]$Type = "Unknown",
        [string]$Premium = "Unknown",
        [hashtable]$AdditionalInfo = @{}
    )
    
    $account = @{
        Source = $Source
        Username = $Username
        UUID = $UUID
        Type = $Type
        Premium = $Premium
        AdditionalInfo = $AdditionalInfo
        Timestamp = Get-Date
    }
    
    $script:foundAccounts += $account
}

function Get-TLauncherProfiles {
    $file = "$env:APPDATA\.minecraft\TlauncherProfiles.json"
    if (-not (Test-Path $file)) {
        Write-Host "`n[TLauncherProfiles.json not found]" -ForegroundColor Gray
        return
    }

    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json
        Write-Host "`n--- TLauncher Profiles ---`n" -ForegroundColor Red
        
        foreach ($acc in $data.accounts.PSObject.Properties) {
            $info = $acc.Value
            if ($info.username -and $info.uuid) {
                $token = $null
                if ($info.microsoftOAuthToken.accessToken) { $token = $info.microsoftOAuthToken.accessToken }
                elseif ($info.microsoftOAuthToken.id_token) { $token = $info.microsoftOAuthToken.id_token }

                $premium = if ($token) { 'yes' } else { 'no' }

                Write-Host ("DisplayName:`t{0}" -f $info.displayName) -ForegroundColor Green
                Write-Host ("UUID:`t`t{0}" -f $info.uuid) -ForegroundColor Gray
                Write-Host ("Type:`t`t{0}" -f $info.type) -ForegroundColor Gray
                Write-Host ("Premium:`t{0}`n" -f $premium) -ForegroundColor Gray

                Add-AccountToReport -Source "TLauncher" -Username $info.displayName -UUID $info.uuid -Type $info.type -Premium $premium

                if ($token) {
                    $claims = Decode-Jwt $token
                    if ($claims) { 
                        $claims | Format-Table -AutoSize 
                        if ($claims.IsExpired) {
                            Write-Host "Token is EXPIRED!" -ForegroundColor Red
                        }
                    }
                    Write-Host ""
                }
            }
        }
    } catch {
        Write-Host "Error reading TLauncherProfiles.json: $_" -ForegroundColor Red
    }
}

function Get-LauncherAccounts {
    $file = "$env:APPDATA\.minecraft\launcher_accounts.json"
    if (-not (Test-Path $file)) {
        Write-Host "`n[launcher_accounts.json not found]" -ForegroundColor Gray
        return
    }

    Write-Host "`n--- Launcher Accounts ---`n" -ForegroundColor Red
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
            Write-Host ("UUID:`t`t{0}" -f $uuid) -ForegroundColor Gray
            Write-Host ("Type:`t`t{0}" -f $type) -ForegroundColor Gray
            Write-Host ("Token:`t{0}`n" -f $token) -ForegroundColor Gray

            Add-AccountToReport -Source "Official Launcher" -Username $info.username -UUID $uuid -Type $type -Premium $token
        }
    } catch {
        Write-Host "Error reading launcher_accounts.json: $_" -ForegroundColor Red
    }
}

function Get-MultiMCAccounts {
    $multiMCPath = "$env:APPDATA\MultiMC\accounts.json"
    if (-not (Test-Path $multiMCPath)) {
        Write-Host "`n[MultiMC accounts.json not found]" -ForegroundColor Gray
        return
    }

    Write-Host "`n--- MultiMC Accounts ---`n" -ForegroundColor Red
    try {
        $data = Get-Content $multiMCPath -Raw | ConvertFrom-Json
        foreach ($acc in $data.accounts) {
            Write-Host ("Username:`t{0}" -f $acc.username) -ForegroundColor Green
            Write-Host ("UUID:`t`t{0}" -f $acc.uuid) -ForegroundColor Gray
            Write-Host ("Type:`t`t{0}`n" -f $acc.type) -ForegroundColor Gray

            Add-AccountToReport -Source "MultiMC" -Username $acc.username -UUID $acc.uuid -Type $acc.type
        }
    } catch {
        Write-Host "Error reading MultiMC accounts: $_" -ForegroundColor Red
    }
}

function Get-BadlionAccounts {
    $badlionPaths = @(
        "$env:APPDATA\.minecraft\Badlion Client\settings.json",
        "$env:APPDATA\Badlion Client\settings.json"
    )

    Write-Host "`n--- Badlion Client ---`n" -ForegroundColor Red
    $found = $false

    foreach ($path in $badlionPaths) {
        if (Test-Path $path) {
            $found = $true
            try {
                $data = Get-Content $path -Raw | ConvertFrom-Json
                if ($data.accounts) {
                    foreach ($acc in $data.accounts.PSObject.Properties) {
                        Write-Host ("Account:`t{0}" -f $acc.Name) -ForegroundColor Green
                        Write-Host ("Details:`t{0}`n" -f ($acc.Value | ConvertTo-Json -Compress)) -ForegroundColor Gray
                        
                        Add-AccountToReport -Source "Badlion Client" -Username $acc.Name -UUID "N/A" -Type "Badlion"
                    }
                }
            } catch {
                Write-Host "Error reading Badlion settings from ${path}: $_" -ForegroundColor Red
            }
        }
    }

    if (-not $found) {
        Write-Host "[Badlion Client not found]" -ForegroundColor Gray
    }
}

function Get-LunarClientAccounts {
    $lunarPaths = @(
        "$env:USERPROFILE\.lunarclient\settings\game\accounts.json",
        "$env:USERPROFILE\.lunarclient\accounts.json"
    )

    Write-Host "`n--- Lunar Client ---`n" -ForegroundColor Red
    $found = $false

    foreach ($path in $lunarPaths) {
        if (Test-Path $path) {
            $found = $true
            try {
                $data = Get-Content $path -Raw | ConvertFrom-Json
                foreach ($acc in $data.PSObject.Properties) {
                    Write-Host ("Username:`t{0}" -f $acc.Name) -ForegroundColor Green
                    if ($acc.Value.uuid) {
                        Write-Host ("UUID:`t`t{0}" -f $acc.Value.uuid) -ForegroundColor Gray
                    }
                    Write-Host ""

                    Add-AccountToReport -Source "Lunar Client" -Username $acc.Name -UUID ($acc.Value.uuid -or "N/A") -Type "Lunar"
                }
            } catch {
                Write-Host "Error reading Lunar Client accounts from ${path}: $_" -ForegroundColor Red
            }
        }
    }

    if (-not $found) {
        Write-Host "[Lunar Client not found]" -ForegroundColor Gray
    }
}

function Get-UsernameCache {
    $file = "$env:APPDATA\.minecraft\usernamecache.json"
    if (-not (Test-Path $file)) {
        Write-Host "`n[usernamecache.json not found]" -ForegroundColor Gray
        return
    }

    Write-Host "`n--- Username Cache ---`n" -ForegroundColor Red
    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json
        if (-not $data) { Write-Host "[usernamecache.json empty]" -ForegroundColor Gray; return }

        foreach ($entry in $data) {
            if ($entry.username -and $entry.uuid) {
                Write-Host ("Username:`t{0}" -f $entry.username) -ForegroundColor Green
                Write-Host ("UUID:`t`t{0}`n" -f $entry.uuid) -ForegroundColor Gray

                Add-AccountToReport -Source "Username Cache" -Username $entry.username -UUID $entry.uuid -Type "Cache"
            }
        }
    } catch {
        Write-Host "Error reading usernamecache.json: $_" -ForegroundColor Red
    }
}

function Get-UserCache {
    $file = "$env:APPDATA\.minecraft\usercache.json"
    if (-not (Test-Path $file)) {
        Write-Host "`n[usercache.json not found]" -ForegroundColor Gray
        return
    }

    Write-Host "`n--- User Cache ---`n" -ForegroundColor Red
    try {
        $data = Get-Content $file -Raw | ConvertFrom-Json
        if (-not $data) { Write-Host "[usercache.json empty]" -ForegroundColor Gray; return }

        foreach ($entry in $data) {
            if ($entry.name -and $entry.uuid) {
                Write-Host ("Name:`t{0}" -f $entry.name) -ForegroundColor Green
                Write-Host ("UUID:`t{0}`n" -f $entry.uuid) -ForegroundColor Gray

                Add-AccountToReport -Source "User Cache" -Username $entry.name -UUID $entry.uuid -Type "Cache"
            }
        }
    } catch {
        Write-Host "Error reading usercache.json: $_" -ForegroundColor Red
    }
}

function Search-AdvancedConfigs {
    Write-Host "`n--- Advanced Config Search ---`n" -ForegroundColor Red
    
    $searchPaths = @(
        "$env:APPDATA\.minecraft",
        "$env:USERPROFILE\.lunarclient",
        "$env:APPDATA\MultiMC",
        "$env:APPDATA\.technic",
        "$env:APPDATA\.atlauncher",
        "$env:APPDATA\gdlauncher_next",
        "$env:APPDATA\PrismLauncher",
        "$env:APPDATA\PolyMC"
    )
    
    $configFiles = @("*.json", "*.properties", "*.cfg", "*.txt")
    $accountKeywords = @("account", "profile", "user", "login", "auth", "token", "uuid", "username")
    
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            Write-Host "Searching: $path" -ForegroundColor Yellow
            foreach ($pattern in $configFiles) {
                try {
                    $files = Get-ChildItem -Path $path -Filter $pattern -Recurse -ErrorAction SilentlyContinue
                    foreach ($file in $files) {
                        $fileName = $file.Name.ToLower()
                        $hasKeyword = $accountKeywords | Where-Object { $fileName -match $_ }
                        
                        if ($hasKeyword) {
                            Write-Host ("Found: {0}" -f $file.FullName) -ForegroundColor Green

                            try {
                                $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                                if ($content -and $content.Length -gt 0) {
                                    $uuidPattern = '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'
                                    $uuids = [regex]::Matches($content, $uuidPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                                    
                                    foreach ($uuid in $uuids) {
                                        Write-Host ("  UUID found: {0}" -f $uuid.Value) -ForegroundColor Cyan
                                    }

                                    if ($fileName -match "\.json$") {
                                        try {
                                            $json = $content | ConvertFrom-Json
                                            $usernameProps = @("username", "displayName", "name", "playerName")
                                            foreach ($prop in $usernameProps) {
                                                if ($json.$prop) {
                                                    Write-Host ("  Username found: {0}" -f $json.$prop) -ForegroundColor Cyan
                                                }
                                            }
                                        } catch {}
                                    }
                                }
                            } catch {}
                        }
                    }
                } catch {}
            }
        }
    }
}

function Analyze-JWTTokens {
    Write-Host "`n--- JWT Token Analysis ---`n" -ForegroundColor Red
    
    $searchPaths = @(
        "$env:APPDATA\.minecraft",
        "$env:USERPROFILE\.lunarclient",
        "$env:APPDATA\MultiMC"
    )
    
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $tokenFiles = Get-ChildItem -Path $path -Filter "*.json" -Recurse -ErrorAction SilentlyContinue
            
            foreach ($file in $tokenFiles) {
                try {
                    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
                    if ($content) {
                        $jwtPattern = 'eyJ[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*\.[A-Za-z0-9_-]*'
                        $tokens = [regex]::Matches($content, $jwtPattern)
                        
                        foreach ($tokenMatch in $tokens) {
                            Write-Host ("JWT found in: {0}" -f $file.Name) -ForegroundColor Yellow
                            $token = $tokenMatch.Value
                            $decoded = Decode-Jwt $token
                            
                            if ($decoded) {
                                Write-Host "Token details:" -ForegroundColor Green

                                if ($decoded.sub) { Write-Host ("Subject: {0}" -f $decoded.sub) -ForegroundColor Cyan }
                                if ($decoded.iss) { Write-Host ("Issuer: {0}" -f $decoded.iss) -ForegroundColor Cyan }
                                if ($decoded.aud) { Write-Host ("Audience: {0}" -f $decoded.aud) -ForegroundColor Cyan }
                                if ($decoded.ExpiryDate) { 
                                    Write-Host ("Expires: {0}" -f $decoded.ExpiryDate) -ForegroundColor Cyan 
                                    if ($decoded.IsExpired) {
                                        Write-Host "TOKEN IS EXPIRED!" -ForegroundColor Red
                                    } else {
                                        Write-Host "Token is still valid" -ForegroundColor Green
                                    }
                                }
                                
                                Write-Host ""
                            }
                        }
                    }
                } catch {}
            }
        }
    }
}

function Get-WindowsEventLogs {
    Write-Host "`n--- Windows Event Logs Analysis ---`n" -ForegroundColor Red
    
    try {
        Write-Host "Searching Application logs..." -ForegroundColor Yellow
        $appEvents = Get-WinEvent -FilterHashtable @{LogName='Application'; StartTime=(Get-Date).AddDays(-7)} -ErrorAction SilentlyContinue |
                     Where-Object { $_.Message -match "minecraft|java.*minecraft|mojang" } |
                     Select-Object -First 5
        
        foreach ($event in $appEvents) {
            Write-Host ("Time: {0}" -f $event.TimeCreated) -ForegroundColor Cyan
            Write-Host ("Source: {0}" -f $event.ProviderName) -ForegroundColor Gray
            $message = $event.Message.Substring(0, [Math]::Min(150, $event.Message.Length))
            Write-Host ("Message: {0}...`n" -f $message) -ForegroundColor Gray
        }

        Write-Host "Searching System logs for Java processes..." -ForegroundColor Yellow
        $sysEvents = Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=(Get-Date).AddDays(-3)} -ErrorAction SilentlyContinue |
                     Where-Object { $_.Message -match "java|javaw" } |
                     Select-Object -First 3
        
        foreach ($event in $sysEvents) {
            Write-Host ("Time: {0}" -f $event.TimeCreated) -ForegroundColor Cyan
            Write-Host ("Event ID: {0}" -f $event.Id) -ForegroundColor Gray
            Write-Host ""
        }
        
    } catch {
        Write-Host "[No relevant Windows events found or insufficient permissions]" -ForegroundColor Gray
    }
}

function Backup-MinecraftConfigs {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $backupPath = "$env:USERPROFILE\Desktop\MinecraftBackup_$timestamp"
    
    try {
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        
        Write-Host "`n--- Creating Backup ---`n" -ForegroundColor Red
        
        $filesToBackup = @(
            @{Path="$env:APPDATA\.minecraft\launcher_accounts.json"; Name="launcher_accounts.json"},
            @{Path="$env:APPDATA\.minecraft\TlauncherProfiles.json"; Name="TlauncherProfiles.json"},
            @{Path="$env:APPDATA\.minecraft\usernamecache.json"; Name="usernamecache.json"},
            @{Path="$env:APPDATA\.minecraft\usercache.json"; Name="usercache.json"},
            @{Path="$env:APPDATA\.minecraft\launcher_profiles.json"; Name="launcher_profiles.json"},
            @{Path="$env:APPDATA\MultiMC\accounts.json"; Name="MultiMC_accounts.json"},
            @{Path="$env:USERPROFILE\.lunarclient\settings\game\accounts.json"; Name="Lunar_accounts.json"}
        )
        
        $backedUpCount = 0
        foreach ($fileInfo in $filesToBackup) {
            if (Test-Path $fileInfo.Path) {
                Copy-Item $fileInfo.Path "$backupPath\$($fileInfo.Name)" -Force
                Write-Host ("Backed up: {0}" -f $fileInfo.Name) -ForegroundColor Green
                $backedUpCount++
            }
        }

        $backupInfo = @{
            Created = Get-Date
            FilesBackedUp = $backedUpCount
            BackupPath = $backupPath
            ComputerName = $env:COMPUTERNAME
            UserName = $env:USERNAME
        }
        
        $backupInfo | ConvertTo-Json | Out-File "$backupPath\backup_info.json" -Encoding UTF8
        
        Write-Host "Backup completed!" -ForegroundColor Green
        Write-Host ("Location: {0}" -f $backupPath) -ForegroundColor Yellow
        Write-Host ("Files backed up: {0}" -f $backedUpCount) -ForegroundColor Yellow
        
    } catch {
        Write-Host "Backup failed: $_" -ForegroundColor Red
    }
}

function Generate-HTMLReport {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $reportPath = "$env:USERPROFILE\Desktop\MinecraftReport_$timestamp.html"

    $uniqueAccounts = $script:foundAccounts | Sort-Object Username -Unique
    $totalAccounts = $uniqueAccounts.Count
    $premiumAccounts = ($uniqueAccounts | Where-Object { $_.Premium -eq 'yes' }).Count
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Minecraft Accounts Report</title>
    <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        :root {
            --primary: #6c5ce7;
            --secondary: #a29bfe;
            --danger: #ff7675;
            --success: #00b894;
            --warning: #fdcb6e;
            --dark: #2d3436;
            --light: #f5f6fa;
            --card-shadow: 0 10px 20px rgba(0,0,0,0.1);
            --transition: all 0.3s ease;
        }
        
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
            color: var(--dark);
            line-height: 1.6;
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
            padding: 20px;
        }
        
        .header {
            background: white;
            padding: 30px;
            border-radius: 15px;
            text-align: center;
            margin-bottom: 30px;
            box-shadow: var(--card-shadow);
            position: relative;
            overflow: hidden;
        }
        
        .header::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 5px;
            background: linear-gradient(90deg, var(--primary), var(--success));
        }
        
        .header h1 {
            color: var(--primary);
            font-size: 2.5rem;
            margin-bottom: 10px;
            font-weight: 700;
        }
        
        .header p {
            color: #666;
            margin-bottom: 5px;
        }
        
        .stats-container {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .stat-card {
            background: white;
            padding: 25px;
            border-radius: 12px;
            text-align: center;
            box-shadow: var(--card-shadow);
            transition: var(--transition);
            border-top: 4px solid var(--primary);
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 30px rgba(0,0,0,0.15);
        }
        
        .stat-icon {
            font-size: 2rem;
            margin-bottom: 15px;
            color: var(--primary);
        }
        
        .stat-number {
            font-size: 2.5rem;
            font-weight: 700;
            color: var(--dark);
            margin-bottom: 5px;
        }
        
        .stat-label {
            color: #666;
            font-size: 0.9rem;
        }
        
        .controls {
            display: flex;
            justify-content: space-between;
            margin-bottom: 20px;
            flex-wrap: wrap;
            gap: 10px;
        }
        
        .filter-controls {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
        }
        
        .btn {
            padding: 10px 20px;
            border-radius: 50px;
            border: none;
            cursor: pointer;
            font-weight: 500;
            transition: var(--transition);
            display: inline-flex;
            align-items: center;
            gap: 8px;
        }
        
        .btn-primary {
            background: var(--primary);
            color: white;
        }
        
        .btn-primary:hover {
            background: #5649d1;
        }
        
        .btn-outline {
            background: transparent;
            border: 1px solid var(--primary);
            color: var(--primary);
        }
        
        .btn-outline:hover {
            background: var(--primary);
            color: white;
        }
        
        .btn-danger {
            background: var(--danger);
            color: white;
        }
        
        .btn-danger:hover {
            background: #e84393;
        }
        
        .search-box {
            padding: 10px 15px;
            border-radius: 50px;
            border: 1px solid #ddd;
            min-width: 250px;
            font-family: inherit;
        }
        
        .accounts-container {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        
        .account-card {
            background: white;
            padding: 20px;
            border-radius: 12px;
            box-shadow: var(--card-shadow);
            transition: var(--transition);
            position: relative;
            overflow: hidden;
        }
        
        .account-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 15px 30px rgba(0,0,0,0.15);
        }
        
        .account-card.premium::after {
            content: 'PREMIUM';
            position: absolute;
            top: 10px;
            right: -30px;
            background: var(--warning);
            color: var(--dark);
            padding: 3px 30px;
            transform: rotate(45deg);
            font-size: 0.7rem;
            font-weight: 600;
        }
        
        .account-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 15px;
            padding-bottom: 15px;
            border-bottom: 1px solid #eee;
        }
        
        .username {
            font-size: 1.3rem;
            font-weight: 600;
            color: var(--dark);
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .username i {
            color: var(--primary);
        }
        
        .source-badge {
            background: #e3f2fd;
            color: var(--primary);
            padding: 4px 12px;
            border-radius: 50px;
            font-size: 0.8rem;
            font-weight: 600;
        }
        
        .account-details {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 12px;
            font-size: 0.9rem;
        }
        
        .detail-item {
            background: #f8f9fa;
            padding: 10px;
            border-radius: 8px;
        }
        
        .detail-label {
            font-weight: 500;
            color: #666;
            font-size: 0.8rem;
            margin-bottom: 5px;
        }
        
        .detail-value {
            font-weight: 500;
            color: var(--dark);
            word-break: break-all;
        }
        
        .footer {
            text-align: center;
            margin-top: 30px;
            padding: 20px;
            background: white;
            border-radius: 12px;
            color: #666;
            box-shadow: var(--card-shadow);
        }
        
        .no-accounts {
            grid-column: 1 / -1;
            text-align: center;
            padding: 40px;
            background: white;
            border-radius: 12px;
            box-shadow: var(--card-shadow);
        }
        
        .no-accounts i {
            font-size: 3rem;
            color: #ddd;
            margin-bottom: 15px;
        }
        
        .hidden {
            display: none !important;
        }
        
        @media (max-width: 768px) {
            .container {
                padding: 10px;
            }
            
            .header h1 {
                font-size: 2rem;
            }
            
            .stat-number {
                font-size: 2rem;
            }
            
            .accounts-container {
                grid-template-columns: 1fr;
            }
            
            .controls {
                flex-direction: column;
            }
            
            .filter-controls {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1><i class="fas fa-user-secret"></i> Minecraft Accounts Report</h1>
            <p>Generated on <span id="report-date"></span></p>
            <p><i class="fas fa-laptop"></i> <span id="computer-name"></span> | <i class="fas fa-user"></i> <span id="user-name"></span></p>
        </div>
        
        <div class="stats-container">
            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-users"></i></div>
                <div class="stat-number" id="total-accounts">0</div>
                <div class="stat-label">Total Accounts</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-crown"></i></div>
                <div class="stat-number" id="premium-accounts">0</div>
                <div class="stat-label">Premium Accounts</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-folder-open"></i></div>
                <div class="stat-number" id="total-sources">0</div>
                <div class="stat-label">Different Sources</div>
            </div>
            <div class="stat-card">
                <div class="stat-icon"><i class="fas fa-clock"></i></div>
                <div class="stat-number" id="last-updated">Now</div>
                <div class="stat-label">Last Updated</div>
            </div>
        </div>
        
        <div class="controls">
            <div class="filter-controls">
                <input type="text" class="search-box" id="search-accounts" placeholder="Search accounts...">
                <button class="btn btn-outline" id="filter-premium">
                    <i class="fas fa-crown"></i> Premium Only
                </button>
                <button class="btn btn-outline" id="filter-cracked">
                    <i class="fas fa-unlock"></i> Cracked Only
                </button>
                <button class="btn btn-outline" id="reset-filters">
                    <i class="fas fa-sync-alt"></i> Reset
                </button>
            </div>
            <button class="btn btn-primary" id="export-json">
                <i class="fas fa-file-export"></i> Export JSON
            </button>
        </div>
        
        <div class="accounts-container" id="accounts-grid">
            <div class="no-accounts">
                <i class="fas fa-user-slash"></i>
                <h3>No accounts found</h3>
                <p>Please run the account detection first</p>
            </div>
        </div>
        
        <div class="footer">
            <p><i class="fas fa-code"></i> Report generated by Enhanced Minecraft Alts Checker v2.0</p>
            <p id="report-summary">No accounts found</p>
        </div>
    </div>

    <script>
        // Sample data - in real implementation this would come from PowerShell
        const accountsData = [
            // This would be populated by the PowerShell script
            // Example:
            /*
            {
                Source: "TLauncher",
                Username: "Player123",
                UUID: "d4a1b2c3-4567-8910-1112-131415161718",
                Type: "Microsoft",
                Premium: "yes",
                Timestamp: "2023-05-15 14:30:22"
            }
            */
        ];
        
        // DOM elements
        const accountsGrid = document.getElementById('accounts-grid');
        const searchInput = document.getElementById('search-accounts');
        const filterPremium = document.getElementById('filter-premium');
        const filterCracked = document.getElementById('filter-cracked');
        const resetFilters = document.getElementById('reset-filters');
        const exportJson = document.getElementById('export-json');
        const totalAccountsEl = document.getElementById('total-accounts');
        const premiumAccountsEl = document.getElementById('premium-accounts');
        const totalSourcesEl = document.getElementById('total-sources');
        const lastUpdatedEl = document.getElementById('last-updated');
        const reportDateEl = document.getElementById('report-date');
        const computerNameEl = document.getElementById('computer-name');
        const userNameEl = document.getElementById('user-name');
        const reportSummaryEl = document.getElementById('report-summary');
        
        // Current filter state
        let currentFilter = 'all';
        let currentSearch = '';
        
        // Initialize the page
        function initPage() {
            // Set report metadata
            reportDateEl.textContent = new Date().toLocaleString();
            computerNameEl.textContent = navigator.userAgent;
            userNameEl.textContent = 'Browser User';
            
            // Load data from localStorage if available
            const savedData = localStorage.getItem('minecraftAccountsData');
            if (savedData) {
                try {
                    const parsedData = JSON.parse(savedData);
                    if (parsedData && parsedData.accounts) {
                        updateUI(parsedData.accounts);
                        return;
                    }
                } catch (e) {
                    console.error('Error parsing saved data:', e);
                }
            }
            
            // If no saved data, use the sample data
            updateUI(accountsData);
        }
        
        // Update the UI with account data
        function updateUI(accounts) {
            // Save to localStorage
            localStorage.setItem('minecraftAccountsData', JSON.stringify({ accounts }));
            
            // Update stats
            const uniqueAccounts = [...new Map(accounts.map(account => 
                [account.UUID, account])).values()];
            const premiumAccounts = uniqueAccounts.filter(acc => acc.Premium === 'yes');
            const sources = [...new Set(uniqueAccounts.map(acc => acc.Source))];
            
            totalAccountsEl.textContent = uniqueAccounts.length;
            premiumAccountsEl.textContent = premiumAccounts.length;
            totalSourcesEl.textContent = sources.length;
            lastUpdatedEl.textContent = 'Just now';
            
            reportSummaryEl.textContent = `This report contains ${uniqueAccounts.length} unique accounts from ${sources.length} different sources`;
            
            // Filter accounts based on current filters
            let filteredAccounts = [...uniqueAccounts];
            
            if (currentFilter === 'premium') {
                filteredAccounts = filteredAccounts.filter(acc => acc.Premium === 'yes');
            } else if (currentFilter === 'cracked') {
                filteredAccounts = filteredAccounts.filter(acc => acc.Premium !== 'yes');
            }
            
            if (currentSearch) {
                const searchTerm = currentSearch.toLowerCase();
                filteredAccounts = filteredAccounts.filter(acc => 
                    acc.Username.toLowerCase().includes(searchTerm) || 
                    acc.UUID.toLowerCase().includes(searchTerm) ||
                    acc.Source.toLowerCase().includes(searchTerm)
                );
            }
            
            // Clear the grid
            accountsGrid.innerHTML = '';
            
            // Show "no accounts" message if filtered list is empty
            if (filteredAccounts.length === 0) {
                const noAccountsEl = document.createElement('div');
                noAccountsEl.className = 'no-accounts';
                noAccountsEl.innerHTML = `
                    <i class="fas fa-user-slash"></i>
                    <h3>No accounts match your filters</h3>
                    <p>Try changing your search or filter criteria</p>
                `;
                accountsGrid.appendChild(noAccountsEl);
                return;
            }
            
            // Add account cards
            filteredAccounts.forEach(account => {
                const accountEl = document.createElement('div');
                accountEl.className = `account-card ${account.Premium === 'yes' ? 'premium' : ''}`;
                
                const typeIcon = account.Type === 'Microsoft' ? 
                    '<i class="fab fa-microsoft"></i>' : 
                    '<i class="fas fa-user"></i>';
                
                const premiumBadge = account.Premium === 'yes' ? 
                    '<span class="premium-badge"><i class="fas fa-crown"></i> Premium</span>' : 
                    '<span class="free-badge"><i class="fas fa-unlock"></i> Free</span>';
                
                accountEl.innerHTML = `
                    <div class="account-header">
                        <div class="username">
                            ${typeIcon} ${account.Username}
                        </div>
                        <div class="source-badge">${account.Source}</div>
                    </div>
                    <div class="account-details">
                        <div class="detail-item">
                            <div class="detail-label">UUID</div>
                            <div class="detail-value">${account.UUID}</div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Type</div>
                            <div class="detail-value">${account.Type}</div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Status</div>
                            <div class="detail-value">${premiumBadge}</div>
                        </div>
                        <div class="detail-item">
                            <div class="detail-label">Found</div>
                            <div class="detail-value">${formatDate(account.Timestamp)}</div>
                        </div>
                    </div>
                `;
                
                accountsGrid.appendChild(accountEl);
            });
        }
        
        // Format date for display
        function formatDate(dateString) {
            if (!dateString) return 'Unknown';
            
            try {
                const date = new Date(dateString);
                return date.toLocaleString();
            } catch {
                return dateString;
            }
        }
        
        // Event listeners
        searchInput.addEventListener('input', (e) => {
            currentSearch = e.target.value.trim();
            updateUI(accountsData);
        });
        
        filterPremium.addEventListener('click', () => {
            currentFilter = currentFilter === 'premium' ? 'all' : 'premium';
            updateUI(accountsData);
            
            // Update button state
            filterPremium.classList.toggle('btn-primary', currentFilter === 'premium');
            filterPremium.classList.toggle('btn-outline', currentFilter !== 'premium');
        });
        
        filterCracked.addEventListener('click', () => {
            currentFilter = currentFilter === 'cracked' ? 'all' : 'cracked';
            updateUI(accountsData);
            
            // Update button state
            filterCracked.classList.toggle('btn-primary', currentFilter === 'cracked');
            filterCracked.classList.toggle('btn-outline', currentFilter !== 'cracked');
        });
        
        resetFilters.addEventListener('click', () => {
            currentFilter = 'all';
            currentSearch = '';
            searchInput.value = '';
            
            // Reset button states
            filterPremium.classList.remove('btn-primary');
            filterPremium.classList.add('btn-outline');
            
            filterCracked.classList.remove('btn-primary');
            filterCracked.classList.add('btn-outline');
            
            updateUI(accountsData);
        });
        
        exportJson.addEventListener('click', () => {
            const dataStr = JSON.stringify(accountsData, null, 2);
            const dataUri = 'data:application/json;charset=utf-8,'+ encodeURIComponent(dataStr);
            
            const exportFileDefaultName = `minecraft-accounts-${new Date().toISOString()}.json`;
            
            const linkElement = document.createElement('a');
            linkElement.setAttribute('href', dataUri);
            linkElement.setAttribute('download', exportFileDefaultName);
            linkElement.click();
        });
        
        // Initialize the page
        document.addEventListener('DOMContentLoaded', initPage);
    </script>
</body>
</html>
"@

    try {
        $html | Out-File $reportPath -Encoding UTF8
        Write-Host "HTML Report generated successfully!" -ForegroundColor Green
        Write-Host ("Report saved: {0}" -f $reportPath) -ForegroundColor Yellow

        $openReport = Read-Host "`nOpen report in browser? (y/n)"
        if ($openReport -eq 'y' -or $openReport -eq 'Y') {
            Start-Process $reportPath
        }
        
    } catch {
        Write-Host "Failed to generate HTML report: $_" -ForegroundColor Red
    }
}

function Export-AccountsCSV {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $csvPath = "$env:USERPROFILE\Desktop\MinecraftAccounts_$timestamp.csv"
    
    try {
        $uniqueAccounts = $script:foundAccounts | Sort-Object Username -Unique
        $csvData = $uniqueAccounts | Select-Object Source, Username, UUID, Type, Premium, @{Name='Timestamp'; Expression={$_.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')}}
        
        $csvData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        
        Write-Host "CSV Export completed!" -ForegroundColor Green
        Write-Host ("File saved: {0}" -f $csvPath) -ForegroundColor Yellow
        Write-Host ("Records exported: {0}" -f $csvData.Count) -ForegroundColor Yellow
        
    } catch {
        Write-Host "CSV Export failed: $_" -ForegroundColor Red
    }
}

function Search-BrowserHistory {
    Write-Host "`n--- Browser History Analysis ---`n" -ForegroundColor Red

    $chromePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\History"
    if (Test-Path $chromePath) {
        Write-Host "Analyzing Chrome history..." -ForegroundColor Yellow
        try {
            $tempPath = "$env:TEMP\chrome_history_temp.db"
            Copy-Item $chromePath $tempPath -Force -ErrorAction SilentlyContinue

            $content = Get-Content $tempPath -Raw -ErrorAction SilentlyContinue
            if ($content) {
                $minecraftUrls = @(
                    "minecraft.net",
                    "mojang.com", 
                    "minecraftservices.com",
                    "login.live.com",
                    "account.microsoft.com"
                )
                
                foreach ($url in $minecraftUrls) {
                    if ($content -match $url) {
                        Write-Host ("Found visits to: {0}" -f $url) -ForegroundColor Green
                    }
                }
            }
            
            Remove-Item $tempPath -Force -ErrorAction SilentlyContinue
        } catch {
            Write-Host "Could not analyze Chrome history" -ForegroundColor Red
        }
    } else {
        Write-Host "Chrome history not found" -ForegroundColor Gray
    }

    $firefoxProfilesPath = "$env:APPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $firefoxProfilesPath) {
        Write-Host "Analyzing Firefox history..." -ForegroundColor Yellow
        try {
            $profiles = Get-ChildItem $firefoxProfilesPath -Directory
            foreach ($profile in $profiles) {
                $historyPath = Join-Path $profile.FullName "places.sqlite"
                if (Test-Path $historyPath) {
                    Write-Host ("Found Firefox profile: {0}" -f $profile.Name) -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "Could not analyze Firefox history" -ForegroundColor Red
        }
    } else {
        Write-Host "Firefox history not found" -ForegroundColor Gray
    }
}

function Get-ProcessInformation {
    Write-Host "`n--- Running Processes Analysis ---`n" -ForegroundColor Red
    
    try {
        $processes = Get-Process | Where-Object { 
            $_.ProcessName -match "java|javaw|minecraft|tlauncher|lunar|badlion|multimc" -or
            $_.MainWindowTitle -match "minecraft|tlauncher|lunar|badlion|multimc"
        }
        
        if ($processes) {
            Write-Host "Found Minecraft-related processes:" -ForegroundColor Yellow
            foreach ($proc in $processes) {
                Write-Host ("Process: {0} (PID: {1})" -f $proc.ProcessName, $proc.Id) -ForegroundColor Green
                if ($proc.MainWindowTitle) {
                    Write-Host ("Window: {0}" -f $proc.MainWindowTitle) -ForegroundColor Cyan
                }

                try {
                    $procInfo = Get-WmiObject Win32_Process -Filter "ProcessId = $($proc.Id)" -ErrorAction SilentlyContinue
                    if ($procInfo -and $procInfo.CommandLine) {
                        $cmdLine = $procInfo.CommandLine
                        if ($cmdLine.Length -gt 100) {
                            $cmdLine = $cmdLine.Substring(0, [Math]::Min(150, $cmdLine.Length))
                        }
                        Write-Host ("Command: {0}..." -f $cmdLine) -ForegroundColor Gray
                    }
                } catch {}
                Write-Host ""
            }
        } else {
            Write-Host "No Minecraft-related processes currently running" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "Could not analyze running processes" -ForegroundColor Red
    }
}

function Search-RegistryEntries {
    Write-Host "`n--- Registry Analysis ---`n" -ForegroundColor Red
    
    try {
        $registryPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall",
            "HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
        )
        
        $minecraftApps = @()
        
        foreach ($path in $registryPaths) {
            try {
                if (Test-Path $path) {
                    $items = Get-ChildItem $path -ErrorAction SilentlyContinue
                    foreach ($item in $items) {
                        try {
                            $displayName = (Get-ItemProperty $item.PSPath -Name "DisplayName" -ErrorAction SilentlyContinue).DisplayName
                            if ($displayName -and $displayName -match "minecraft|tlauncher|lunar|badlion|multimc|java") {
                                $minecraftApps += @{
                                    Name = $displayName
                                    Path = $item.PSPath
                                    Publisher = (Get-ItemProperty $item.PSPath -Name "Publisher" -ErrorAction SilentlyContinue).Publisher
                                    Version = (Get-ItemProperty $item.PSPath -Name "DisplayVersion" -ErrorAction SilentlyContinue).DisplayVersion
                                }
                            }
                        } catch {}
                    }
                }
            } catch {}
        }
        
        if ($minecraftApps.Count -gt 0) {
            Write-Host "Found installed Minecraft-related applications:" -ForegroundColor Yellow
            foreach ($app in $minecraftApps) {
                Write-Host ("Name: {0}" -f $app.Name) -ForegroundColor Green
                if ($app.Publisher) { Write-Host ("Publisher: {0}" -f $app.Publisher) -ForegroundColor Cyan }
                if ($app.Version) { Write-Host ("Version: {0}" -f $app.Version) -ForegroundColor Cyan }
                Write-Host ""
            }
        } else {
            Write-Host "No Minecraft-related applications found in registry" -ForegroundColor Gray
        }
        
    } catch {
        Write-Host "Could not analyze registry entries" -ForegroundColor Red
    }
}

function Show-AccountSummary {
    Clear-Host
    Write-Host "`n--- ACCOUNT SUMMARY ---`n" -ForegroundColor Red -BackgroundColor Black
    
    if ($script:foundAccounts.Count -eq 0) {
        Write-Host "No accounts have been scanned yet. Please run account detection first." -ForegroundColor Yellow
        return
    }
    
    $uniqueAccounts = $script:foundAccounts | Sort-Object Username -Unique
    $totalAccounts = $uniqueAccounts.Count
    $premiumCount = ($uniqueAccounts | Where-Object { $_.Premium -eq 'yes' }).Count
    $sources = $uniqueAccounts | Group-Object Source
    
    Write-Host "STATISTICS" -ForegroundColor Yellow
    Write-Host ("Total Unique Accounts: {0}" -f $totalAccounts) -ForegroundColor Green
    Write-Host ("Premium Accounts: {0}" -f $premiumCount) -ForegroundColor Green
    Write-Host ("Cracked/Free Accounts: {0}" -f ($totalAccounts - $premiumCount)) -ForegroundColor Green
    Write-Host ""
    
    Write-Host "SOURCES BREAKDOWN" -ForegroundColor Yellow
    foreach ($source in $sources) {
        Write-Host ("{0}: {1} accounts" -f $source.Name, $source.Count) -ForegroundColor Cyan
    }
    Write-Host ""

    Write-Host "ACCOUNT DETAILS" -ForegroundColor Yellow
    foreach ($account in $uniqueAccounts | Sort-Object Username) {
        $premiumIcon = if ($account.Premium -eq 'yes') { '[Premium]' } else { '[Free]' }
        Write-Host ("{0} {1} ({2}) - {3}" -f $premiumIcon, $account.Username, $account.Source, $account.Type) -ForegroundColor White
    }
}

function Print-MainMenu {
    Clear-Host
    Print-AnimatedLogo
    Write-Host ""
    Write-Host "                                    ======================================" -ForegroundColor Red
    Write-Host "                                         ENHANCED ALTS-CHECKER TOOL v2.0  " -ForegroundColor Red
    Write-Host "                                    ======================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "                                   1. Open Log Folders" -ForegroundColor Gray
    Write-Host "                                   2. Search Deleted Logs" -ForegroundColor Gray
    Write-Host "                                   3. Show All Minecraft Accounts" -ForegroundColor Gray
    Write-Host "                                   4. Scan Other Launchers" -ForegroundColor Yellow
    Write-Host "                                   5. Advanced Config Search" -ForegroundColor Yellow
    Write-Host "                                   6. Analyze JWT Tokens" -ForegroundColor Yellow
    Write-Host "                                   7. Windows Event Logs" -ForegroundColor Yellow
    Write-Host "                                   8. Browser History Analysis" -ForegroundColor Yellow
    Write-Host "                                   9. Backup Configurations" -ForegroundColor Yellow
    Write-Host "                                   10. Account Summary" -ForegroundColor Cyan
    Write-Host "                                   11. Generate HTML Report" -ForegroundColor Cyan
    Write-Host "                                   12. Export to CSV" -ForegroundColor Cyan
    Write-Host "                                   13. System Analysis" -ForegroundColor Magenta
    Write-Host "                                   14. Exit" -ForegroundColor Gray
    Write-Host ""
    Write-Host ("                                Accounts found so far: {0}" -f $script:foundAccounts.Count) -ForegroundColor Green
    Write-Host ""
    $choice = Read-Host "                                    Select an option (1-14)"
    return $choice
}

Write-Host "Initializing Enhanced Minecraft Alts Checker..." -ForegroundColor Yellow
Start-Sleep -Seconds 1

while ($true) {
    $choice = Print-MainMenu

    switch ($choice) {
        "1" {
            Clear-Host
            Write-Host "Opening log folders..." -ForegroundColor Gray
            $folders = @(
                "$env:APPDATA\.minecraft\logs",
                "$env:APPDATA\.minecraft\logs\blclient\minecraft\",
                "$env:USERPROFILE\.lunarclient\offline\1.8\logs",
                "$env:USERPROFILE\.lunarclient\offline\multiver\logs"
            )
            
            foreach ($folder in $folders) {
                if (Test-Path $folder) {
                    Start-Process -FilePath $folder
                    Write-Host ("Opened: {0}" -f $folder) -ForegroundColor Green
                } else {
                    Write-Host ("Not found: {0}" -f $folder) -ForegroundColor Red
                }
            }
            Pause
        }
        "2" {
            Clear-Host
            Write-Host "Searching for deleted logs..." -ForegroundColor Yellow
            Write-Host "This may take a few minutes..." -ForegroundColor Gray
            
            try {
                Set-Location C:\
                $logFile = "minecraft_deleted_logs_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
                
                fsutil usn readjournal C: csv | 
                    findstr /i /C:"0x80000200" | 
                    findstr /i /C:"latest.log" /i /C:".log.gz" /i /C:"launcher_profiles.json" /i /C:"usernamecache.json" /i /C:"usercache.json" /i /C:"shig.inima" /i /C:"launcher_accounts.json" > $logFile
                
                if (Test-Path $logFile) {
                    $lineCount = (Get-Content $logFile).Count
                    Write-Host ("Found {0} deleted log entries" -f $lineCount) -ForegroundColor Green
                    Start-Process -FilePath "notepad.exe" -ArgumentList $logFile
                } else {
                    Write-Host "No deleted logs found or insufficient permissions" -ForegroundColor Red
                }
            } catch {
                Write-Host ("Error searching deleted logs: $_") -ForegroundColor Red
            }
            Pause
        }
        "3" {
            Clear-Host
            Write-Host "Scanning all Minecraft accounts..." -ForegroundColor Yellow
            $script:foundAccounts = @()
            
            Get-TLauncherProfiles
            Get-LauncherAccounts
            Get-UsernameCache
            Get-UserCache
            
            Write-Host "Scan completed!" -ForegroundColor Green
            Write-Host ("Total accounts found: {0}" -f $script:foundAccounts.Count) -ForegroundColor Cyan
            Pause
        }
        "4" {
            Clear-Host
            Write-Host "Scanning other launchers..." -ForegroundColor Yellow
            
            Get-MultiMCAccounts
            Get-BadlionAccounts
            Get-LunarClientAccounts
            
            Write-Host "Other launchers scan completed!" -ForegroundColor Green
            Pause
        }
        "5" {
            Clear-Host
            Write-Host "Starting advanced configuration search..." -ForegroundColor Yellow
            Write-Host "This will search all common Minecraft directories for configuration files..." -ForegroundColor Gray
            
            Search-AdvancedConfigs
            
            Write-Host "Advanced search completed!" -ForegroundColor Green
            Pause
        }
        "6" {
            Clear-Host
            Write-Host "Analyzing JWT tokens..." -ForegroundColor Yellow
            
            Analyze-JWTTokens
            
            Write-Host "Token analysis completed!" -ForegroundColor Green
            Pause
        }
        "7" {
            Clear-Host
            Write-Host "Analyzing Windows Event Logs..." -ForegroundColor Yellow
            Write-Host "Searching for Minecraft-related system events..." -ForegroundColor Gray
            
            Get-WindowsEventLogs
            
            Write-Host "Event log analysis completed!" -ForegroundColor Green
            Pause
        }
        "8" {
            Clear-Host
            Write-Host "Analyzing browser history..." -ForegroundColor Yellow
            
            Search-BrowserHistory
            
            Write-Host "Browser analysis completed!" -ForegroundColor Green
            Pause
        }
        "9" {
            Clear-Host
            Write-Host "Creating backup of Minecraft configurations..." -ForegroundColor Yellow
            
            Backup-MinecraftConfigs
            
            Pause
        }
        "10" {
            Show-AccountSummary
            Pause
        }
        "11" {
            Clear-Host
            Write-Host "Generating comprehensive HTML report..." -ForegroundColor Yellow
            
            if ($script:foundAccounts.Count -eq 0) {
                Write-Host "No accounts found. Please run account detection first." -ForegroundColor Red
            } else {
                Generate-HTMLReport
            }
            
            Pause
        }
        "12" {
            Clear-Host
            Write-Host "Exporting accounts to CSV..." -ForegroundColor Yellow
            
            if ($script:foundAccounts.Count -eq 0) {
                Write-Host "No accounts found. Please run account detection first." -ForegroundColor Red
            } else {
                Export-AccountsCSV
            }
            
            Pause
        }
        "13" {
            Clear-Host
            Write-Host "Running comprehensive system analysis..." -ForegroundColor Yellow
            
            Get-ProcessInformation
            Search-RegistryEntries
            
            Write-Host "System analysis completed!" -ForegroundColor Green
            Pause
        }
        "14" {
            Clear-Host
            Write-Host ""
            Write-Host "                                    ═══════════════════════════════" -ForegroundColor Red
            Write-Host "                                          Thank you for using      " -ForegroundColor Red  
            Write-Host "                                      Enhanced Alts Checker v2.0   " -ForegroundColor Red
            Write-Host "                                    ═══════════════════════════════" -ForegroundColor Red
            Write-Host ""
            Write-Host "                                     Goodbye and happy gaming!" -ForegroundColor Yellow
            Write-Host ""
            Start-Sleep -Seconds 2
            break
        }
        default {
            Write-Host "Invalid option. Please select a number between 1-14." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}
