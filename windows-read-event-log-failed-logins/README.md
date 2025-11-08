# Windows Event Log - Failed Login Reader

Scripts to read and display failed login attempts from Windows Security Event Log (Event ID 4625).

## 📁 Files in this folder

- `read-failed-logins.ps1` - Main PowerShell script that reads Event ID 4625
- `read-failed-logins.bat` - Batch file wrapper with parameter support
- `failed-test1.ps1` - Test script to generate sample failed login events

## ✨ Features

- **Human-readable error code translation** from NTSTATUS codes and Windows constants
- **Clean, formatted output** ready for webhooks, emails, or logging systems
- **Configurable time range** (default: last 24 hours)
- **Webhook-ready data collection** via `$eventData` variable
- **Professional error handling** with helpful diagnostic messages

## 🚀 Quick Start

### Basic Usage
```bash
# Default: last 24 hours, max 50 events
.\read-failed-logins.bat
```

### Advanced Usage
```bash
# Custom time range: last 2 hours
.\read-failed-logins.bat 2

# Custom time and count: last 2 hours, max 100 events
.\read-failed-logins.bat 2 100

# Show help
.\read-failed-logins.bat help
```

### PowerShell Direct Usage
```powershell
# Import and run the script
.\read-failed-logins.ps1 -HoursBack 4 -MaxEvents 25
```

## 📋 Requirements

- **Windows OS** with PowerShell 5.1 or higher
- **Administrator privileges** to read Security Event Log
- **Audit policy enabled** for logon events:
  ```cmd
  auditpol /set /subcategory:"Logon/Logoff" /success:enable /failure:enable
  ```

## 📊 Example Output

```
Reading failed login attempts from Windows Event Log...
Looking for events from the last 24 hour(s), showing up to 50 events

Found 2 failed login event(s):
================================================================================

=== Failed Login Event ===
Time:           2025-11-08 10:05:14
Username:       nonexistent_user_123
Domain:         -
Workstation:    NTLM
IP Address:     -
Logon Type:     Invalid logon type (STATUS_INVALID_HANDLE - authentication process error)
Failure Status: Logon failure
Sub Status:     Logon failure: unknown user name or bad password
Process Name:   0
----------------------------------------

Collected event data:
=== Failed Login Event ===
Time:           2025-11-08 10:05:14
Username:       nonexistent_user_123
Domain:         -
Workstation:    NTLM
IP Address:     -
Logon Type:     Invalid logon type (STATUS_INVALID_HANDLE - authentication process error)
Failure Status: Logon failure
Sub Status:     Logon failure: unknown user name or bad password
Process Name:   0
----------------------------------------

Variable `$eventData` contains all events formatted for further processing.
You can use it for webhook, email notifications, etc.
```

## 🔧 Error Code Translations

### NTSTATUS Codes
| Hex Code | Decimal | Meaning |
|----------|---------|---------|
| 0xC0000064 | -1073741820 | User account does not exist |
| 0xC000006A | -1073741814 | Wrong password |
| 0xC000006D | -1073741811 | Logon failure |
| 0xC0000234 | -1073741516 | Account locked out |

### Windows Constants
| Constant | Decimal | Meaning |
|----------|---------|---------|
| %%2313 | 1326 | Logon failure: unknown user name or bad password |
| %%2304 | 1326 | Unknown user or bad password |
| %%2307 | 1329 | Account locked |
| %%2309 | 1331 | Account disabled |

### Logon Types
| Type | Description |
|------|-------------|
| 2 | Interactive (local logon) |
| 3 | Network (remote access) |
| 4 | Batch (scheduled task) |
| 5 | Service (Windows service) |
| 10 | RemoteInteractive (RDP) |
| 11 | CachedInteractive (cached logon) |

## 🛠️ Integration Examples

### Webhook Usage
```powershell
# Run the script and use the collected data
.\read-failed-logins.bat

# In another PowerShell session or script:
Invoke-RestMethod -Uri "https://your-webhook-url.com" -Method Post -Body @{
    message = $eventData
    title = "Failed Login Alert"
} | ConvertTo-Json -ContentType "application/json"
```

### Email Notification
```powershell
# Send via SMTP
Send-MailMessage -To "admin@company.com" -From "alerts@company.com" -Subject "Failed Login Alert" -Body $eventData -SmtpServer "smtp.company.com"
```

### Logging to File
```powershell
# Append to log file
Add-Content -Path "C:\Logs\failed_logins.log" -Value $eventData
```

## 🔍 Troubleshooting

### No Events Found
```
Possible reasons:
- Audit policy not enabled for logon events
- No failed login attempts recently
- Insufficient permissions to read Security log

To enable audit policy, run as Administrator:
auditpol /set /subcategory:'Logon/Logoff' /success:enable /failure:enable
```

### Access Denied
- **Solution:** Run the script as Administrator
- **Command:** Right-click `read-failed-logins.bat` → "Run as administrator"

### Script Won't Run
- **Solution:** Enable PowerShell execution policy
- **Command:** `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## 🧪 Testing

Use the included test script to generate sample failed login events:

```bash
# Generate test failed login events
.\failed-test1.ps1

# Then check the results
.\read-failed-logins.bat
```

## 📝 Technical Details

- **Event Source:** Windows Security Event Log
- **Event ID:** 4625 (An account failed to log on)
- **Parsing Method:** Direct access to event Properties array for reliability
- **Output Format:** Human-readable blocks with aligned columns
- **Memory Usage:** Efficient processing of large event sets

## 🤝 Contributing

Found a bug or want to add features? Submit an issue or pull request!

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file in the root directory.
