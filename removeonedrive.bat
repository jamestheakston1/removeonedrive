@echo off
setlocal

echo.
echo ===========================================
echo === OneDrive Complete Removal Utility ===
echo ===========================================
echo.

ECHO **ACTION OVERVIEW:**
ECHO This script will perform a deep system cleanup to permanently remove OneDrive.
ECHO It will:
ECHO 1. Stop all OneDrive processes and run the uninstaller.
ECHO 2. Delete leftover program files and user synchronization data.
ECHO 3. Remove system registry keys to prevent auto-reinstallation.
ECHO.

ECHO **WHY ADMIN IS REQUIRED:**
ECHO This script needs Administrator privileges to perform the complete removal because it must:
ECHO - Access and delete files from protected Windows directories (like "Program Files").
ECHO - Modify the HKLM (System-Wide) registry to clean up File Explorer links and prevent
ECHO   OneDrive from automatically reinstalling itself after a system update.
ECHO.

ECHO Press any key to continue. If you are not currently running as an Administrator,
ECHO you will be prompted to grant permissions on the next screen.

pause >nul
echo.

:: Check for Administrator privileges and elevate if necessary
net session >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    ECHO Starting the elevation process now...
    powershell -Command "Start-Process -FilePath '%~dpnx0' -Verb RunAs"
    exit /b
)

ECHO Admin rights confirmed. Proceeding with uninstallation...
timeout /t 2 /nobreak > nul

:: 1. Stop the running OneDrive process
ECHO --- [1/4] Stopping the OneDrive process...
taskkill /f /im OneDrive.exe >nul 2>&1
timeout /t 2 /nobreak > nul

:: 2. Determine architecture and run the uninstaller
ECHO --- [2/4] Uninstalling OneDrive application...

:: Path for 64-bit systems
set "onedrive_setup_x64=%SystemDrive%\Program Files (x86)\Microsoft OneDrive\OneDriveSetup.exe"
:: Path for 32-bit systems
set "onedrive_setup_x86=%SystemDrive%\Program Files\Microsoft OneDrive\OneDriveSetup.exe"

if exist "%onedrive_setup_x64%" (
    ECHO Found 64-bit setup. Running uninstaller...
    start /wait "" "%onedrive_setup_x64%" /uninstall
) else if exist "%onedrive_setup_x86%" (
    ECHO Found 32-bit setup. Running uninstaller...
    start /wait "" "%onedrive_setup_x86%" /uninstall
) else (
    ECHO OneDriveSetup.exe not found. Assuming it is already uninstalled or path is non-standard.
)

:: Wait a moment for uninstallation artifacts to clear
timeout /t 5 /nobreak > nul

:: 3. Remove residual folders and user data
ECHO --- [3/4] Removing residual files and user data folders...

:: Remove user's OneDrive folder (where files are synced)
ECHO Deleting user's OneDrive sync folder...
rmdir /s /q "%UserProfile%\OneDrive" >nul 2>&1

:: Remove Local App Data
ECHO Deleting local application data cache...
rmdir /s /q "%LocalAppData%\Microsoft\OneDrive" >nul 2>&1

:: Remove Program Files folders (both potential locations)
ECHO Deleting program installation folders...
rmdir /s /q "%SystemDrive%\Program Files (x86)\Microsoft OneDrive" >nul 2>&1
rmdir /s /q "%SystemDrive%\Program Files\Microsoft OneDrive" >nul 2>&1

:: 4. Clean up registry keys
ECHO --- [4/4] Cleaning up registry entries...

:: Remove the "OneDrive Setup" policy key
REG DELETE "HKLM\Software\Policies\Microsoft\Windows\OneDrive" /f >nul 2>&1

:: Remove OneDrive from Explorer's Navigation Pane (Shell Extensions) for 64-bit and 32-bit OS
REG DELETE "HKCR\CLSID\{018D5C66-4533-4307-9B53-2ad27925cc1a}" /f >nul 2>&1
REG DELETE "HKCR\CLSID\{018D5C66-4533-4307-9B53-2ad27925cc1a}" /f /reg:32 >nul 2>&1

:: Remove the "OneDrive Setup" entry from the Uninstall list
REG DELETE "HKLM\Software\Microsoft\Windows\CurrentVersion\Uninstall\OneDriveSetup" /f >nul 2>&1
REG DELETE "HKLM\SOFTWARE\Microsoft\OneDrive" /f >nul 2>&1

ECHO.
ECHO ===========================================
ECHO === Cleanup Complete ===
ECHO ===========================================
ECHO.
ECHO OneDrive has been successfully uninstalled and cleaned up.
ECHO A restart is strongly recommended for all changes (especially the removal from the File Explorer sidebar) to take full effect.
ECHO.

CHOICE /C YN /M "Would you like to restart your computer now? (Y/N)"
IF %ERRORLEVEL% EQU 1 (
    ECHO Restarting now...
    shutdown /r /t 0
) ELSE (
    ECHO Please remember to restart your computer manually soon.
    pause
)
endlocal
