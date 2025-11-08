# Test script for failed login attempts monitoring
# Copyright (c) 2024 BITBACK

param(
    [string]$TestUser = "nonexistent_user_$(Get-Random)",
    [int]$Attempts = 10
)

Write-Host "Starting failed login attempts test..." -ForegroundColor Yellow
Write-Host "This will generate $Attempts failed authentication events" -ForegroundColor Yellow
Write-Host "Check your RMM for alerts after running this script (threshold: 5 attempts/hour)" -ForegroundColor Yellow
Write-Host ""

for ($i = 1; $i -le $Attempts; $i++) {
    Write-Host "Attempt $i of $Attempts - Testing with user: $TestUser" -ForegroundColor Cyan

    try {
        # Use net use with invalid credentials to generate failed login event
        # Try to connect to non-existent network share with wrong credentials
        $null = net use \\localhost\nonexistent_share /user:$TestUser "wrongpassword" 2>&1

    } catch {
        Write-Host "Expected error occurred: $($_.Exception.Message)" -ForegroundColor Green
    }

    Start-Sleep -Seconds 1  # Small delay between attempts
}

Write-Host ""
Write-Host "Test completed. Check Windows Event Viewer (Security log, Event ID 4625) and your RMM dashboard for failed login alerts." -ForegroundColor Green
