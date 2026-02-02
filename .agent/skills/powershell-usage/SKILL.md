---
name: powershell-usage
description: terminal usage rules for windows environments
---

# PowerShell Usage

Always follow these rules when using the terminal in this environment.

## Rules

- Always assume the terminal is PowerShell (not bash) when running commands on Windows.
- Verify the shell environment (e.g., check `$PSVersionTable`) if in doubt, but default to PowerShell syntax.
- Use PowerShell-native commands where possible (e.g., `Get-ChildItem` instead of `find`).
- Be mindful of path separators (`\` on Windows).
