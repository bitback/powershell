@echo off
echo Reading failed login attempts from Windows Event Log...
echo.

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [OK] Running with administrator privileges
) else (
    echo [WARNING] Not running as administrator. Some events may not be visible.
    echo To read Security log properly, run this batch file as Administrator.
    echo.
)

REM Check for command line arguments
if "%1"=="" goto :default
if "%1"=="help" goto :show_help

REM Custom parameters - check if numeric
echo %1| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 goto :invalid_param

if "%2"=="" goto :hours_only
echo %2| findstr /r "^[0-9][0-9]*$" >nul
if errorlevel 1 goto :invalid_param

REM Hours and max events
echo Checking last %1 hours, max %2 events...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0read-failed-logins.ps1" -HoursBack %1 -MaxEvents %2
goto :end

:default
    REM Default: last 24 hours, max 50 events
    echo Using default settings: last 24 hours, max 50 events
    echo.
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0read-failed-logins.ps1"
    goto :end

:hours_only
    REM Only hours specified
    echo Checking last %1 hours...
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0read-failed-logins.ps1" -HoursBack %1
    goto :end

:show_help
    echo Usage: %0 [hours] [max_events]
    echo.
    echo Examples:
    echo   %0                    - Default: last 24 hours, max 50 events
    echo   %0 2                  - Last 2 hours
    echo   %0 2 100              - Last 2 hours, max 100 events
    echo   %0 help               - Show this help
    echo.
    goto :end

:invalid_param
    echo [ERROR] Invalid parameter format
    echo Use '%0 help' for usage information
    goto :end

:end
echo.
echo Press any key to exit...
pause > nul
