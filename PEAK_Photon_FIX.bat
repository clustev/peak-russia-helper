@echo off
setlocal EnableExtensions EnableDelayedExpansion
title PEAK Photon ClientTimeout FIX v3

fltmc >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "VER=1.10.2"
set "URL=https://github.com/Flowseal/zapret-discord-youtube/releases/download/1.10.2/zapret-discord-youtube-1.10.2.zip"
set "SHA=5EAAC9FB2E4B1ABD693487452A3FF3F4DFE9578A45F9DDDDF A4BC1F5A6BB62D5"
set "SHA=%SHA: =%"
set "BASE=C:\PEAK-Photon-zapret"
set "ROOT=%BASE%\zapret-discord-youtube-%VER%"
set "ZIP=%BASE%\zapret-discord-youtube-%VER%.zip"
set "STATE=%ProgramData%\PEAK-Photon-Fix"
set "SVC_MARK=%STATE%\old_zapret_service_was_running.flag"
set "DEF_MARK=%STATE%\defender_exclusion_added.flag"

if not exist "%STATE%" mkdir "%STATE%" >nul 2>&1

echo.
echo ================================================================
echo  PEAK Photon ClientTimeout FIX v3
echo ================================================================
echo.

echo [1/8] Preparing dedicated folder...
if not exist "%BASE%" mkdir "%BASE%" >nul 2>&1

rem Add a narrow Microsoft Defender exclusion for the dedicated folder.
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$p='%BASE%'; try { $prefs=Get-MpPreference -ErrorAction Stop; if ($prefs.ExclusionPath -notcontains $p) { Add-MpPreference -ExclusionPath $p -ErrorAction Stop; Set-Content -LiteralPath '%DEF_MARK%' -Value '1' -Encoding ASCII } } catch {}" >nul 2>&1

if not exist "%ROOT%\service.bat" (
    echo [2/8] Downloading official Flowseal %VER%...
    if exist "%ZIP%" del /f /q "%ZIP%" >nul 2>&1

    where curl.exe >nul 2>&1
    if not errorlevel 1 (
        curl.exe -L --fail --retry 3 --connect-timeout 15 -o "%ZIP%" "%URL%"
    ) else (
        powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
          "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -UseBasicParsing -Uri '%URL%' -OutFile '%ZIP%'"
    )
    if errorlevel 1 (
        echo.
        echo [ERROR] Download failed.
        pause
        exit /b 10
    )

    echo [3/8] Verifying SHA256...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
      "$h=(Get-FileHash -LiteralPath '%ZIP%' -Algorithm SHA256).Hash.ToUpper(); if($h -ne '%SHA%'){Write-Host ('BAD SHA256: '+$h); exit 2}else{Write-Host ('SHA256 OK: '+$h); exit 0}"
    if errorlevel 1 (
        echo.
        echo [ERROR] SHA256 mismatch. Archive will not be used.
        del /f /q "%ZIP%" >nul 2>&1
        pause
        exit /b 11
    )

    echo [4/8] Extracting official archive...
    if exist "%ROOT%" rmdir /s /q "%ROOT%" >nul 2>&1
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
      "Unblock-File -LiteralPath '%ZIP%' -ErrorAction SilentlyContinue; Expand-Archive -LiteralPath '%ZIP%' -DestinationPath '%BASE%' -Force"
    if errorlevel 1 (
        echo.
        echo [ERROR] Extraction failed.
        pause
        exit /b 12
    )
) else (
    echo [2/8] Existing installation found.
    echo [3/8] Download/hash check not needed.
    echo [4/8] Extraction not needed.
)

rem The official release ZIP contains a top-level folder:
rem zapret-discord-youtube-1.10.2\
if not exist "%ROOT%\service.bat" (
    echo.
    echo [ERROR] service.bat is still missing in:
    echo %ROOT%
    echo.
    echo The archive itself is valid, so antivirus likely removed files.
    echo Check Windows Security ^> Protection history.
    pause
    exit /b 13
)

if not exist "%ROOT%\bin\winws.exe" (
    echo.
    echo [ERROR] winws.exe is missing in:
    echo %ROOT%\bin
    echo.
    echo This is normally antivirus quarantine of WinDivert/winws.
    echo Check Windows Security ^> Protection history.
    pause
    exit /b 14
)

echo [5/8] Configuring PEAK mode...

rem Game Filter = TCP + UDP
> "%ROOT%\utils\game_filter.enabled" echo all

rem IPSet Filter = ANY: official service.bat defines an empty ipset-all.txt as "any".
if exist "%ROOT%\lists\ipset-all.txt" (
    if not exist "%ROOT%\lists\ipset-all.txt.peak-backup" (
        copy /y "%ROOT%\lists\ipset-all.txt" "%ROOT%\lists\ipset-all.txt.peak-backup" >nul 2>&1
    )
)
type nul > "%ROOT%\lists\ipset-all.txt"

echo [6/8] Stopping conflicting zapret instance...
if exist "%SVC_MARK%" del /f /q "%SVC_MARK%" >nul 2>&1

sc.exe query "zapret" 2>nul | findstr /I "RUNNING" >nul 2>&1
if not errorlevel 1 (
    > "%SVC_MARK%" echo 1
    sc.exe stop "zapret" >nul 2>&1
    timeout /t 2 /nobreak >nul
)

taskkill /F /IM winws.exe >nul 2>&1

echo [7/8] Starting ALT10 strategy...
set "NO_UPDATE_CHECK=1"
pushd "%ROOT%"
call "general (ALT10).bat"
popd

timeout /t 3 /nobreak >nul
tasklist /FI "IMAGENAME eq winws.exe" 2>nul | findstr /I "winws.exe" >nul
if errorlevel 1 (
    echo.
    echo [ERROR] winws.exe did not stay running.
    echo Check Windows Security ^> Protection history.
    pause
    exit /b 20
)

echo [8/8] Starting PEAK...
echo.
echo ================================================================
echo  FIX IS RUNNING
echo  Game Filter: TCP + UDP
echo  IPSet Filter: ANY
echo  Strategy: ALT10
echo ================================================================
echo.
start "" "steam://rungameid/3527290"

echo.
echo After playing, run PEAK_Photon_STOP.bat
timeout /t 6 /nobreak >nul
exit /b 0
