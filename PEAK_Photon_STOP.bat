@echo off
setlocal EnableExtensions
title Stop PEAK Photon FIX v3

fltmc >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "VER=1.10.2"
set "BASE=C:\PEAK-Photon-zapret"
set "ROOT=%BASE%\zapret-discord-youtube-%VER%"
set "STATE=%ProgramData%\PEAK-Photon-Fix"
set "SVC_MARK=%STATE%\old_zapret_service_was_running.flag"
set "DEF_MARK=%STATE%\defender_exclusion_added.flag"

echo Stopping winws...
taskkill /F /IM winws.exe >nul 2>&1
timeout /t 1 /nobreak >nul

if exist "%ROOT%\lists\ipset-all.txt.peak-backup" (
    echo Restoring original ipset list...
    copy /y "%ROOT%\lists\ipset-all.txt.peak-backup" "%ROOT%\lists\ipset-all.txt" >nul 2>&1
    del /f /q "%ROOT%\lists\ipset-all.txt.peak-backup" >nul 2>&1
)

if exist "%ROOT%\utils\game_filter.enabled" (
    del /f /q "%ROOT%\utils\game_filter.enabled" >nul 2>&1
)

if exist "%SVC_MARK%" (
    echo Restoring previously running zapret service...
    sc.exe start "zapret" >nul 2>&1
    del /f /q "%SVC_MARK%" >nul 2>&1
)

if exist "%DEF_MARK%" (
    echo Removing temporary Defender exclusion...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
      "try { Remove-MpPreference -ExclusionPath '%BASE%' -ErrorAction Stop } catch {}" >nul 2>&1
    del /f /q "%DEF_MARK%" >nul 2>&1
)

echo Done.
timeout /t 2 /nobreak >nul
exit /b 0
