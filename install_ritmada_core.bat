@echo off
setlocal EnableDelayedExpansion

title Ritmada Core v2.5 UNBOUND - Deployment Utility
color 0A

echo ===============================================================================
echo   [RITMADA CORE v2.5 // UNBOUND] ANTIGRAVITY ENVIRONMENT DEPLOYMENT
echo ===============================================================================
echo.

:: 1. Detect Antigravity .gemini Path
set "TARGET_DIR="

:: Check explicit environment overrides
if defined GEMINI_HOME if exist "%GEMINI_HOME%" set "TARGET_DIR=%GEMINI_HOME%"
if not defined TARGET_DIR if defined ANTIGRAVITY_HOME if exist "%ANTIGRAVITY_HOME%" set "TARGET_DIR=%ANTIGRAVITY_HOME%"

:: Check standard user profile path
if not defined TARGET_DIR if exist "%USERPROFILE%\.gemini" set "TARGET_DIR=%USERPROFILE%\.gemini"

:: Check alternate drive or system roots
if not defined TARGET_DIR if exist "%HOMEDRIVE%%HOMEPATH%\.gemini" set "TARGET_DIR=%HOMEDRIVE%%HOMEPATH%\.gemini"

:: Check AppData Roaming / Local Antigravity if customized
if not defined TARGET_DIR if exist "%APPDATA%\.gemini" set "TARGET_DIR=%APPDATA%\.gemini"

:: Default fallback is standard %USERPROFILE%\.gemini
if not defined TARGET_DIR set "TARGET_DIR=%USERPROFILE%\.gemini"

echo [*] Resolved Antigravity path: "!TARGET_DIR!"

:: 2. Locate Archive Bundle
set "ZIP_NAME=ritmada_core_bundle.zip"
set "BUNDLE_PATH=%~dp0%ZIP_NAME%"

if not exist "!BUNDLE_PATH!" set "BUNDLE_PATH=%USERPROFILE%\Desktop\%ZIP_NAME%"
if not exist "!BUNDLE_PATH!" set "BUNDLE_PATH=%CD%\%ZIP_NAME%"

if not exist "!BUNDLE_PATH!" (
    color 0C
    echo.
    echo [ERROR] Bundle archive "!ZIP_NAME!" not found in:
    echo         - "%~dp0"
    echo         - "%USERPROFILE%\Desktop"
    echo         - "%CD%"
    echo.
    echo Please ensure "!ZIP_NAME!" is in the same directory as this script.
    echo.
    pause
    exit /b 1
)

echo [*] Located archive bundle:    "!BUNDLE_PATH!"
echo.

:: 3. Generate Locale-Safe Timestamp & Create Safety Backup
for /f %%A in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss" 2^>nul') do set "TS=%%A"
if not defined TS set "TS=%RANDOM%_%RANDOM%"

set "BACKUP_DIR=%USERPROFILE%\.gemini_backup_!TS!"

if exist "!TARGET_DIR!" (
    echo [*] Creating safety backup of current .gemini to:
    echo     "!BACKUP_DIR!"
    robocopy "!TARGET_DIR!" "!BACKUP_DIR!" /E /NFL /NDL /NJH /NJS /nc /ns /np >nul 2>&1
    echo [+] Backup secured.
    echo.

    echo [*] Wiping old configuration and domain files from "!TARGET_DIR!"...
    if exist "!TARGET_DIR!\GEMINI.md" del /f /q "!TARGET_DIR!\GEMINI.md" >nul 2>&1
    if exist "!TARGET_DIR!\UNIVERSAL_CORE.md" del /f /q "!TARGET_DIR!\UNIVERSAL_CORE.md" >nul 2>&1
    if exist "!TARGET_DIR!\rules" rmdir /s /q "!TARGET_DIR!\rules" >nul 2>&1
    if exist "!TARGET_DIR!\domains" rmdir /s /q "!TARGET_DIR!\domains" >nul 2>&1
    if exist "!TARGET_DIR!\references" rmdir /s /q "!TARGET_DIR!\references" >nul 2>&1
    if exist "!TARGET_DIR!\config\plugins" rmdir /s /q "!TARGET_DIR!\config\plugins" >nul 2>&1
    if exist "!TARGET_DIR!\config\skills" rmdir /s /q "!TARGET_DIR!\config\skills" >nul 2>&1
    echo [+] Old configuration wiped cleanly.
) else (
    echo [*] Target directory does not exist. Initializing "!TARGET_DIR!"...
    mkdir "!TARGET_DIR!" >nul 2>&1
)

echo.

:: 4. Extract New Bundle Archive
echo [*] Deploying Ritmada Core bundle into "!TARGET_DIR!"...

set "EXTRACT_OK=0"
tar --version >nul 2>&1
if %ERRORLEVEL% equ 0 (
    tar -xf "!BUNDLE_PATH!" -C "!TARGET_DIR!"
    if !errorlevel! equ 0 set "EXTRACT_OK=1"
)

if "!EXTRACT_OK!"=="0" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -LiteralPath '!BUNDLE_PATH!' -DestinationPath '!TARGET_DIR!' -Force"
    if !errorlevel! equ 0 set "EXTRACT_OK=1"
)

if "!EXTRACT_OK!"=="0" (
    color 0C
    echo.
    echo [ERROR] Failed to extract archive bundle.
    pause
    exit /b 1
)

echo [+] Extraction complete.
echo.

:: 5. Verification Phase
echo [*] Verifying deployment integrity...
set "VERIFY_FAILED=0"

if not exist "!TARGET_DIR!\GEMINI.md" (
    echo [!] Missing: GEMINI.md
    set "VERIFY_FAILED=1"
)
if not exist "!TARGET_DIR!\rules\GEMINI.md" (
    echo [!] Missing: rules\GEMINI.md
    set "VERIFY_FAILED=1"
)
if not exist "!TARGET_DIR!\domains\systems.md" (
    echo [!] Missing: domains\systems.md
    set "VERIFY_FAILED=1"
)
if not exist "!TARGET_DIR!\config\config.json" (
    echo [!] Missing: config\config.json
    set "VERIFY_FAILED=1"
)
if not exist "!TARGET_DIR!\config\skills" (
    echo [!] Missing: config\skills directory
    set "VERIFY_FAILED=1"
)

if "!VERIFY_FAILED!"=="1" (
    color 0C
    echo.
    echo [WARNING] Verification detected missing critical components.
    echo           Check archive bundle integrity.
    pause
    exit /b 1
)

echo [+] All core modules, rules, and skills successfully deployed and verified.
echo.
echo ===============================================================================
echo   [SUCCESS] RITMADA CORE v2.5 INSTALLED INTO !TARGET_DIR!
echo ===============================================================================
echo.
echo Restart Antigravity to load the newly installed skills and system parameters.
echo.
pause
exit /b 0
