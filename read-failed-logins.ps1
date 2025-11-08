# PowerShell script to read and display failed login attempts from Windows Event Log
# Event ID 4625 (An account failed to log on)
# Displays events in human-readable format with translated error codes
#
# This script reads Windows Security Event Log for failed authentication events,
# parses the raw event data, and displays it in a clean, readable format.
# Error codes are translated from NTSTATUS and Windows constants to human-readable text.
#
# Usage:
#   .\read-failed-logins.ps1                    # Default: last 24 hours, max 50 events
#   .\read-failed-logins.ps1 -HoursBack 2       # Last 2 hours
#   .\read-failed-logins.ps1 -HoursBack 2 -MaxEvents 100  # Custom time and count
#
# Requirements:
#   - Run as Administrator to read Security Event Log
#   - Audit policy must be enabled for logon events
#
# Copyright (c) 2025 BITBACK

param(
    [int]$HoursBack = 24,  # Default: last 24 hours
    [int]$MaxEvents = 50
)

# Function to translate NTSTATUS codes to human readable text
function Get-NTStatusDescription {
    param([string]$StatusCode)
    
    # Handle Windows constants in %%XXXX format
    if ($StatusCode -match "^%%(\d+)$") {
        $constNumber = [int]$matches[1]
        switch ($constNumber) {
            2313 { return "Logon failure: unknown user name or bad password" }
            2304 { return "Unknown user or bad password (STATUS_LOGON_FAILURE)" }
            2307 { return "Account locked (STATUS_ACCOUNT_LOCKED_OUT)" }
            2309 { return "Account disabled (STATUS_ACCOUNT_DISABLED)" }
            2310 { return "Password expired (STATUS_PASSWORD_EXPIRED)" }
            2311 { return "Account expired (STATUS_ACCOUNT_EXPIRED)" }
            default { return "Windows constant %%$constNumber" }
        }
    }
    
    # Try to convert to int for numerical codes
    try {
        $intCode = [int]$StatusCode
        # Convert decimal to hex for easier matching
        $hexCode = "0x{0:X8}" -f $intCode
        
        switch ($hexCode) {
            "0xC0000064" { return "User account does not exist" }
            "0xC000006A" { return "Wrong password" }
            "0xC000006D" { return "Logon failure" }
            "0xC000006E" { return "Account restriction" }
            "0xC000006F" { return "Invalid logon hours" }
            "0xC0000070" { return "Invalid workstation" }
            "0xC0000071" { return "Password expired" }
            "0xC0000072" { return "Account disabled" }
            "0xC000015B" { return "Logon type not granted" }
            "0xC0000193" { return "Account expired" }
            "0xC0000224" { return "Password must change" }
            "0xC0000234" { return "Account locked out" }
            default { return "Unknown error ($hexCode)" }
        }
    } catch {
        # If conversion fails, return as-is
        return "Status: $StatusCode"
    }
}

# Function to translate logon type to human readable text
function Get-LogonTypeDescription {
    param([int]$LogonType)
    
    # Handle negative values (likely error codes)
    if ($LogonType -lt 0) {
        $hexCode = "0x{0:X8}" -f $LogonType
        switch ($hexCode) {
            "0xC00000FC" { return "Invalid logon type (STATUS_INVALID_HANDLE - authentication process error)" }
            default { return "Invalid logon type/error code ($hexCode)" }
        }
    }
    
    switch ($LogonType) {
        2 { return "Interactive (local logon)" }
        3 { return "Network (remote access)" }
        4 { return "Batch (scheduled task)" }
        5 { return "Service (Windows service)" }
        6 { return "Proxy" }
        7 { return "Unlock (unlock workstation)" }
        8 { return "NetworkCleartext" }
        9 { return "NewCredentials" }
        10 { return "RemoteInteractive (RDP/Terminal Services)" }
        11 { return "CachedInteractive (cached logon)" }
        default { return "Type $LogonType (unrecognized)" }
    }
}

Write-Host "Reading failed login attempts from Windows Event Log..." -ForegroundColor Yellow
Write-Host "Looking for events from the last $HoursBack hour(s), showing up to $MaxEvents events" -ForegroundColor Yellow
Write-Host ""

try {
    # Get failed logon events (Event ID 4625) from Security log
    $events = Get-WinEvent -FilterHashtable @{
        LogName = 'Security'
        ID = 4625
        StartTime = (Get-Date).AddHours(-$HoursBack)
    } -MaxEvents $MaxEvents -ErrorAction Stop

    if ($events.Count -eq 0) {
        Write-Host "No failed login events found in the last $HoursBack hour(s)." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Possible reasons:" -ForegroundColor Cyan
        Write-Host "- Audit policy not enabled for logon events" -ForegroundColor White
        Write-Host "- No failed login attempts recently" -ForegroundColor White
        Write-Host "- Insufficient permissions to read Security log" -ForegroundColor White
        Write-Host ""
        Write-Host "To enable audit policy, run as Administrator:" -ForegroundColor Green
        Write-Host "auditpol /set /subcategory:'Logon/Logoff' /success:enable /failure:enable" -ForegroundColor White
        return
    }

    Write-Host "Found $($events.Count) failed login event(s):" -ForegroundColor Green
    Write-Host ("=" * 80) -ForegroundColor Gray

    # Parse events using Properties array (more reliable than text parsing)
    $failedLogins = foreach ($logEvent in $events) {
        [PSCustomObject]@{
            TimeCreated           = $logEvent.TimeCreated
            TargetUserName        = $logEvent.Properties[5].Value   # Konto, które próbowało się zalogować
            TargetDomainName      = $logEvent.Properties[6].Value   # Domena konta
            FailureStatus         = $logEvent.Properties[7].Value   # Główny kod błędu
            SubStatus            = $logEvent.Properties[8].Value   # Szczegółowy kod błędu
            LogonType            = $logEvent.Properties[9].Value   # Typ logowania (2=lokalne, 3=sieć, 10=RDP)
            LogonProcessName     = $logEvent.Properties[10].Value  # Proces logowania
            WorkstationName      = $logEvent.Properties[12].Value  # Nazwa komputera źródłowego
            IpAddress            = $logEvent.Properties[18].Value  # Adres IP źródła
            ProcessName          = $logEvent.Properties[17].Value  # Proces, który inicjował logowanie
        }
    }

    # Display results in text format and collect data for further processing
    $eventData = ""
    foreach ($login in $failedLogins) {
        $eventBlock = @"
=== Failed Login Event ===
Time:           $($login.TimeCreated.ToString('yyyy-MM-dd HH:mm:ss'))
Username:       $($login.TargetUserName)
Domain:         $($login.TargetDomainName)
Workstation:    $($login.WorkstationName)
IP Address:     $($login.IpAddress)
Logon Type:     $(Get-LogonTypeDescription $login.LogonType)
Failure Status: $(Get-NTStatusDescription $login.FailureStatus)
Sub Status:     $(Get-NTStatusDescription $login.SubStatus)
Process Name:   $($login.ProcessName)
----------------------------------------

"@
        
        Write-Host $eventBlock -ForegroundColor White
        # Collect for further processing (webhook, email, etc.)
        $eventData += $eventBlock
    }

    # Output collected data (can be used for webhook, email, etc.)
    Write-Host "Collected event data:" -ForegroundColor Green
    Write-Host $eventData -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Variable `$eventData` contains all events formatted for further processing." -ForegroundColor Yellow
    Write-Host "You can use it for webhook, email notifications, etc." -ForegroundColor Gray

} catch {
    Write-Host "Error reading event log: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure you run this script as Administrator!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Script completed." -ForegroundColor Green
