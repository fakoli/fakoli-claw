' Hidden launcher for push-host-metrics.ps1 — runs PowerShell with no visible console
' window (window style 0) so the 5-minute scheduled task never flashes a terminal.
' Scheduled task action: wscript.exe C:\Users\sdoum\fakoli-push-metrics.vbs
CreateObject("WScript.Shell").Run "powershell -NoProfile -ExecutionPolicy Bypass -File ""C:\Users\sdoum\fakoli-push-metrics.ps1""", 0, False
