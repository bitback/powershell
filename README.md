# powershell
Random powershell scripts for sharing with community

## Windows Event Log - Failed Login Reader

Scripts to read and display failed login attempts from Windows Security Event Log.

### Location: `windows-read-event-log-failed-logins/`

**Files:**
- `read-failed-logins.ps1` - Main PowerShell script that reads Event ID 4625
- `read-failed-logins.bat` - Batch file wrapper with parameter support
- `failed-test1.ps1` - Test script to generate sample failed login events

**Features:**
- Human-readable error code translation from NTSTATUS codes
- Clean, formatted output ready for webhooks/emails
- Configurable time range (default: 24 hours)
- Supports Windows constants (%%2313, etc.)

**Usage:**
```bash
cd windows-read-event-log-failed-logins

# Default: last 24 hours, max 50 events
.\read-failed-logins.bat

# Custom time range: last 2 hours
.\read-failed-logins.bat 2

# Custom time and count: last 2 hours, max 100 events
.\read-failed-logins.bat 2 100
```

**Requirements:**
- Windows with PowerShell
- Run as Administrator
- Audit policy enabled for logon events

**Example Output:**
```
=== Failed Login Event ===
Time:           2025-11-08 10:05:14
Username:       nonexistent_user
Domain:         -
Workstation:    NTLM
IP Address:     -
Logon Type:     Invalid logon type (STATUS_INVALID_HANDLE - authentication process error)
Failure Status: Logon failure
Sub Status:     Logon failure: unknown user name or bad password
Process Name:   0
----------------------------------------
```
