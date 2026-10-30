@echo off

setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"

call :log INFO "Launcher started. Args: %*"

if /i "%~1"=="--worker" goto worker

set "HORIZON_VERSIONS=%APPDATA%\horizon-launcher\versions"

set /a HORIZON_COUNT=0

echo.

echo Installed Horizon versions:

for /f "delims=" %%D in ('dir /b /ad /o-n "%HORIZON_VERSIONS%" 2^>nul') do (

 if exist "%HORIZON_VERSIONS%\%%D\horizon-client.exe" if exist "%HORIZON_VERSIONS%\%%D\horizon-prepare.exe" if exist "%HORIZON_VERSIONS%\%%D\research-lock.json" (

  set /a HORIZON_COUNT+=1

  set "HORIZON_!HORIZON_COUNT!=%HORIZON_VERSIONS%\%%D"

  echo !HORIZON_COUNT!^) %%D

 )

)

if !HORIZON_COUNT! EQU 0 (echo No valid Horizon installations found.& exit /b 10)

set /p "HORIZON_SELECTION=Choose version number (1-!HORIZON_COUNT!): "

set "HORIZON_HOME="

for %%N in (!HORIZON_SELECTION!) do set "HORIZON_HOME=!HORIZON_%%N!"

if not defined HORIZON_HOME (echo Invalid Horizon selection.& exit /b 11)

echo Selected Horizon: "!HORIZON_HOME!"

echo.

echo Launch modes:

echo   1^) Fast launch (use verified prepared cache)

echo   2^) Repair and launch (full verification and preparation)

echo   3^) Verify/repair cache only

echo   4^) Prepare only (do not launch)

set /p "MODE_SELECTION=Choose mode number (1-4): "

set "LAUNCH_MODE="

if "!MODE_SELECTION!"=="1" set "LAUNCH_MODE=fast"

if "!MODE_SELECTION!"=="2" set "LAUNCH_MODE=repair"

if "!MODE_SELECTION!"=="3" set "LAUNCH_MODE=verify"

if "!MODE_SELECTION!"=="4" set "LAUNCH_MODE=prepare"

if not defined LAUNCH_MODE (echo Invalid mode selection.& exit /b 12)

call "%~f0" --worker --mode !LAUNCH_MODE! --horizon "!HORIZON_HOME!"

set "RC=%ERRORLEVEL%"

call :log INFO "Launcher finished with code %RC%"

echo.

if "%RC%"=="0" (echo Finished successfully.) else (echo Stopped with error code %RC%. Errors are shown above.)

echo Press any key to close this window...

pause >nul

exit /b %RC%

:worker

shift

set "MODE=repair"

if /i "%~1"=="--mode" set "MODE=%~2"

shift

shift

if /i "%~1"=="--horizon" set "HORIZON_HOME=%~2"

if not defined HORIZON_HOME (call :fail 10 "Horizon path argument missing"& exit /b 10)

if /i not "%MODE%"=="fast" if /i not "%MODE%"=="repair" if /i not "%MODE%"=="verify" if /i not "%MODE%"=="prepare" (call :fail 12 "Invalid worker mode"& exit /b 12)

set "HROOT=%HORIZON_HOME%"

set "VERSIONS=%APPDATA%\horizon-launcher\versions"

set "CLIENT=%HROOT%\horizon-client.exe"

set "PREPARE=%HROOT%\horizon-prepare.exe"

set "MANIFEST=%HROOT%\.local\minecraft\26.3\manifest.json"

set "SERVER=%HROOT%\.local\minecraft\26.3\server.jar"

set "RESOURCES=%HROOT%\.local\horizon-client\26.3"

set "READY_MARKER=%HROOT%\.local\state\horizon-ready-26.3.txt"

set "BACKUPS=%USERPROFILE%\Documents\Horizon-backups"

set "MINECRAFT_DIR="

set "SAVE_SOURCE="

call :progress 1 "Finding Horizon"



set "HROOT="



if defined HORIZON_HOME if exist "%HORIZON_HOME%\horizon-client.exe" if exist "%HORIZON_HOME%\horizon-prepare.exe" if exist "%HORIZON_HOME%\research-lock.json" set "HROOT=%HORIZON_HOME%"



if not defined HROOT if exist "%VERSIONS%" for /f "delims=" %%D in ('dir /b /ad /o-d "%VERSIONS%" 2^>nul') do if not defined HROOT if exist "%VERSIONS%\%%D\horizon-client.exe" if exist "%VERSIONS%\%%D\horizon-prepare.exe" if exist "%VERSIONS%\%%D\research-lock.json" set "HROOT=%VERSIONS%\%%D"



if not defined HROOT (call :fail 10 "Horizon not found under %VERSIONS%"& exit /b 10)



set "CLIENT=%HROOT%\horizon-client.exe"



set "PREPARE=%HROOT%\horizon-prepare.exe"



set "MANIFEST=%HROOT%\.local\minecraft\26.3\manifest.json"



set "SERVER=%HROOT%\.local\minecraft\26.3\server.jar"



set "RESOURCES=%HROOT%\.local\horizon-client\26.3"



set "READY_MARKER=%HROOT%\.local\state\horizon-ready-26.3.txt"



echo [INFO] Horizon: "%HROOT%"



call :progress 2 "Locating Minecraft 26.3 for saves"



if not defined MINECRAFT_DIR if exist "%APPDATA%\.minecraft\saves" set "MINECRAFT_DIR=%APPDATA%\.minecraft"



if not defined MINECRAFT_DIR if exist "%USERPROFILE%\.minecraft\saves" set "MINECRAFT_DIR=%USERPROFILE%\.minecraft"



if not defined MINECRAFT_DIR if exist "%APPDATA%\.tlauncher\saves" set "MINECRAFT_DIR=%APPDATA%\.tlauncher"



if not defined MINECRAFT_DIR echo [INFO] Minecraft game directory not detected; save sync will be skipped.



set "MCDIR=%MINECRAFT_DIR%"



if defined MINECRAFT_DIR set "SAVE_SOURCE=%MINECRAFT_DIR%\saves"



rem Fast Launch trusts the existing Horizon-prepared resources; never runs Minecraft cache verification.
if /i "%MODE%"=="fast" (
  if not exist "%RESOURCES%\horizon-resources.json" (call :fail 32 "Prepared Horizon resources are missing. Choose Repair and launch first."& exit /b 32)
  echo [FAST] Existing prepared resources found; skipping all verification and preparation.
  goto runtime
)



call :progress 3 "Creating Horizon-owned verified manifest, artifacts and Java 25"



set "SETUP_PS1=%TEMP%\horizon-setup-%RANDOM%-%RANDOM%.ps1"



set "SETUP_B64_1=cGFyYW0oDQ0KICBbUGFyYW1ldGVyKE1hbmRhdG9yeT0kdHJ1ZSldW3N0cmluZ10kUm9vdA0NCikNDQokRXJyb3JBY3Rpb25QcmVmZXJlbmNlID0gJ1N0b3AnDQ0KZnVuY3Rpb24gTG9nLVNldHVwKFtzdHJpbmddJExldmVsLFtzdHJpbmddJE1lc3NhZ2UpIHsNDQogICRsaW5lPSdbezB9XSBbezF9XSB7Mn0nIC1mIChHZXQtRGF0ZSAtRm9ybWF0ICd5eXl5LU1NLWRkIEhIOm1tOnNzLmZmZicpLCRMZXZlbCwkTWVzc2FnZQ0NCiAgV3JpdGUtT3V0cHV0ICRsaW5lDQ0KfQ0NCg0NCiRQcm9ncmVzc1ByZWZlcmVuY2UgPSAnQ29udGludWUnCmZ1bmN0aW9uIExvZy1TZXR1cChbc3RyaW5nXSRMZXZlbCxbc3RyaW5nXSRNZXNzYWdlKSB7CiAgJGxpbmU9J1t7MH1dIFt7MX1dIHsyfScgLWYgKEdldC1EYXRlIC1Gb3JtYXQgJ3l5eXktTU0tZGQgSEg6bW06c3MuZmZmJyksJExldmVsLCRNZXNzYWdlCiAgV3JpdGUtT3V0cHV0ICRsaW5lCn0KdHJhcCB7CiAgJGVycj0oJF8gfCBPdXQtU3RyaW5nKS5UcmltKCkKICBMb2ctU2V0dXAgRVJST1IgJGVycgogIExvZy1TZXR1cCBFUlJPUiAkXy5JbnZvY2F0aW9uSW5mby5Qb3NpdGlvbk1lc3NhZ2UKICBleGl0IDEKfQ0NCiR2ZXJzaW9uID0gJzI2LjMnDQ0KJG1hbmlmZXN0U2hhMSA9ICcxMWYxYWVmZTQ3M2VlZmJhMGFmNjJlMzI4NmMzM2I2OTI4MDdiMmViJw0NCiRtYW5pZmVzdFVybCA9ICJodHRwczovL3Bpc3Rvbi1tZXRhLm1vamFuZy5jb20vdjEvcGFja2FnZXMvJG1hbmlmZXN0U2hhMS8kdmVyc2lvbi5qc29uIg0NCiRjbGllbnRTaGExID0gJ2U4NzdiNmEwN2FjZDYzM2ZiM2JiNDc1MDAyMTc1Y2VjMDM2ZTdiODcnDQ0KJHNlcnZlclNoYTEgPSAnMzM2ODBmNWYyYWMzMjg2NGQ2ZDdjZjVlNTZhNzA1ZmRiM2UwNWY0YycNDQokc2VydmVyVXJsID0gImh0dHBzOi8vcGlzdG9uLWRhdGEubW9qYW5nLmNvbS92MS9vYmplY3RzLyRzZXJ2ZXJTaGExL3NlcnZlci5qYXIiDQ0KV3JpdGUtT3V0cHV0ICgnW0lORk9dIFNldHVwIHJvb3Q6ICcgKyAkUm9vdCkKJGRpciA9IEpvaW4tUGF0aCAkUm9vdCAnLmxvY2FsL21pbmVjcmFmdC8yNi4zJw0NCk5ldy1JdGVtIC1JdGVtVHlwZSBEaXJlY3RvcnkgLUZvcmNlIC1QYXRoICRkaXIgfCBPdXQtTnVsbA0NCg0NCiMgQWx3YXlzIGZldGNoIHRoZSBpbW11dGFibGUgcGlubmVkIE1vamFuZyBtYW5pZmVzdCBpbnRvIEhvcml6b24ncyBvd24gY2FjaGUuDQ0KIyBOZXZlciB0cnVzdCBvciBtb2RpZnkgdGhlIHNvdXJjZSBsYXVuY2hlcidzIHZlcnNpb24gSlNPTi4NDQokbWFuaWZlc3QgPSBKb2luLVBhdGggJGRpciAnbWFuaWZlc3QuanNvbicNDQppZiAoVGVzdC1QYXRoIC1MaXRlcmFsUGF0aCAkbWFuaWZlc3QpIHsNDQogICRjYWNoZWRNYW5pZmVzdEhhc2ggPSAoR2V0LUZpbGVIYXNoIC1MaXRlcmFsUGF0aCAkbWFuaWZlc3QgLUFsZ29yaXRobSBTSEExKS5IYXNoLlRvTG93ZXJJbnZhcmlhbnQoKQ0NCiAgaWYgKCRjYWNoZWRNYW5pZmVzdEhhc2ggLWVxICRtYW5pZmVzdFNoYTEpIHsNDQogICAgV3JpdGUtT3V0cHV0ICdbQ0FDSEVdIE9mZmljaWFsIG1hbmlmZXN0IGFscmVhZHkgdmVyaWZpZWQ7IGRvd25sb2FkIHNraXBwZWQuJw0NCiAgfSBlbHNlIHsNDQogICAgUmVtb3ZlLUl0ZW0gLUxpdGVyYWxQYXRoICRtYW5pZmVzdCAtRm9yY2UNDQogIH0NDQp9DQ0KaWYgKCEoVGVzdC1QYXRoIC1MaXRlcmFsUGF0aCAkbWFuaWZlc3QpKSB7DQ0KICAkdG1wTWFuaWZlc3QgPSAiJG1hbmlmZXN0LmRvd25sb2FkIg0NCiAgSW52b2tlLVdlYlJlcXVlc3QgLVVzZUJhc2ljUGFyc2luZyAtVXJpICRtYW5pZmVzdFVybCAtT3V0RmlsZSAkdG1wTWFuaWZlc3QNDQogIGlmICgoR2V0LUZpbGVIYXNoICR0bXBNYW5pZmVzdCAtQWxnb3JpdGhtIFNIQTEpLkhhc2guVG9Mb3dlckludmFyaWFudCgpIC1uZSAkbWFuaWZlc3RTaGExKSB7IFJlbW92ZS1JdGVtICR0bXBNYW5pZmVzdCAtRm9yY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWU7IHRocm93ICdPZmZpY2lhbCBtYW5pZmVzdCBTSEEtMSBtaXNtYXRjaC4nIH0NDQogIE1vdmUtSXRlbSAtRm9yY2UgLUxpdGVyYWxQYXRoICR0bXBNYW5pZmVzdCAtRGVzdGluYXRpb24gJG1hbmlmZXN0DQ0K"



set "SETUP_B64_2=fQ0NCiRtID0gR2V0LUNvbnRlbnQgLVJhdyAtTGl0ZXJhbFBhdGggJG1hbmlmZXN0IHwgQ29udmVydEZyb20tSnNvbg0NCmlmICgkbS5pZCAtbmUgJHZlcnNpb24gLW9yICRtLmRvd25sb2Fkcy5jbGllbnQuc2hhMSAtbmUgJGNsaWVudFNoYTEgLW9yICRtLmRvd25sb2Fkcy5zZXJ2ZXIuc2hhMSAtbmUgJHNlcnZlclNoYTEgLW9yICRtLmphdmFWZXJzaW9uLm1ham9yVmVyc2lvbiAtbmUgMjUpIHsgdGhyb3cgJ09mZmljaWFsIG1hbmlmZXN0IGNvbnRlbnRzIGRvIG5vdCBtYXRjaCB0aGUgcGlubmVkIEhvcml6b24gY29udHJhY3QuJyB9DQ0KDQ0KDQ0KIyBEb3dubG9hZCB0aGUgc2VydmVyIGFydGlmYWN0IHRvIHRoZSBleHBsaWNpdCAtLXNlcnZlci1qYXIgcGF0aCBhbmQgdmVyaWZ5IGl0cyBwaW5uZWQgU0hBLTEuDQ0KIyBTdXBwbHkgYSBwcml2YXRlIG9mZmljaWFsLWxheW91dCBNaW5lY3JhZnQgdHJlZSBzbyBIb3Jpem9uIG5ldmVyIHJlYWRzIGEgbGF1bmNoZXIncyBtdXRhYmxlIEpTT04uDQ0KV3JpdGUtT3V0cHV0ICdbUFJPR1JFU1NdIFByZXBhcmluZyBwcml2YXRlIE1pbmVjcmFmdCB0cmVlJw0KJHNvdXJjZVJvb3RzID0gQCgKICAoSm9pbi1QYXRoICRlbnY6QVBQREFUQSAnLm1pbmVjcmFmdCcpLAogIChKb2luLVBhdGggJGVudjpVU0VSUFJPRklMRSAnLm1pbmVjcmFmdCcpLAogIChKb2luLVBhdGggJGVudjpBUFBEQVRBICcudGxhdW5jaGVyJykKKSB8IFdoZXJlLU9iamVjdCB7IFRlc3QtUGF0aCAtTGl0ZXJhbFBhdGggJF8gfQpmdW5jdGlvbiBDb3B5LVZlcmlmaWVkRnJvbVNvdXJjZShbc3RyaW5nXSREZXN0aW5hdGlvbixbc3RyaW5nXSRSZWxhdGl2ZVBhdGgsW3N0cmluZ10kRXhwZWN0ZWRTaGExKSB7CiAgZm9yZWFjaCAoJHNvdXJjZVJvb3QgaW4gJHNvdXJjZVJvb3RzKSB7CiAgICAkY2FuZGlkYXRlID0gSm9pbi1QYXRoICRzb3VyY2VSb290ICgkUmVsYXRpdmVQYXRoIC1yZXBsYWNlICcvJywgJ1wnKQogICAgaWYgKCEoVGVzdC1QYXRoIC1MaXRlcmFsUGF0aCAkY2FuZGlkYXRlKSkgeyBjb250aW51ZSB9CiAgICB0cnkgewogICAgICAkaGFzaCA9IChHZXQtRmlsZUhhc2ggLUxpdGVyYWxQYXRoICRjYW5kaWRhdGUgLUFsZ29yaXRobSBTSEExKS5IYXNoLlRvTG93ZXJJbnZhcmlhbnQoKQogICAgICBpZiAoJGhhc2ggLW5lICRFeHBlY3RlZFNoYTEuVG9Mb3dlckludmFyaWFudCgpKSB7IGNvbnRpbnVlIH0KICAgICAgTmV3LUl0ZW0gLUl0ZW1UeXBlIERpcmVjdG9yeSAtRm9yY2UgLVBhdGggKFNwbGl0LVBhdGggLVBhcmVudCAkRGVzdGluYXRpb24pIHwgT3V0LU51bGwKICAgICAgQ29weS1JdGVtIC1MaXRlcmFsUGF0aCAkY2FuZGlkYXRlIC1EZXN0aW5hdGlvbiAkRGVzdGluYXRpb24gLUZvcmNlCiAgICAgIFdyaXRlLU91dHB1dCAiW0NBQ0hFXSBSZXVzZWQgdmVyaWZpZWQgc291cmNlIGZpbGU6ICRSZWxhdGl2ZVBhdGgiCiAgICAgIHJldHVybiAkdHJ1ZQogICAgfSBjYXRjaCB7IFdyaXRlLU91dHB1dCAiW1dBUk5dIFNvdXJjZSBjYWNoZSBjb3B5IGZhaWxlZCBmb3IgJHtSZWxhdGl2ZVBhdGh9OiAkKCRfLkV4Y2VwdGlvbi5NZXNzYWdlKSIgfQogIH0KICByZXR1cm4gJGZhbHNlCn0KV3JpdGUtT3V0cHV0ICgnW0lORk9dIFNlYXJjaGluZyBleGlzdGluZyBsYXVuY2hlciBjYWNoZXM6ICcgKyAoJHNvdXJjZVJvb3RzIC1qb2luICc7ICcpKQokcHJpdmF0ZUdhbWUgPSBKb2luLVBhdGggJFJvb3QgJy5sb2NhbC9taW5lY3JhZnQtc291cmNlLzI2LjMnDQ0KJHByaXZhdGVWZXJzaW9uID0gSm9pbi1QYXRoICRwcml2YXRlR2FtZSAndmVyc2lvbnMvMjYuMycNDQpOZXctSXRlbSAtSXRlbVR5cGUgRGlyZWN0b3J5IC1Gb3JjZSAtUGF0aCAkcHJpdmF0ZVZlcnNpb24gfCBPdXQtTnVsbA0NCkNvcHktSXRlbSAtRm9yY2UgLUxpdGVyYWxQYXRoICRtYW5pZmVzdCAtRGVzdGluYXRpb24gKEpvaW4tUGF0aCAkcHJpdmF0ZVZlcnNpb24gJzI2LjMuanNvbicpDQ0KJGNsaWVudCA9IEpvaW4tUGF0aCAkcHJpdmF0ZVZlcnNpb24gJzI2LjMuamFyJw0NCmlmICghKFRlc3QtUGF0aCAkY2xpZW50KSAtb3IgKEdldC1GaWxlSGFzaCAkY2xpZW50IC1BbGdvcml0aG0gU0hBMSkuSGFzaC5Ub0xvd2Vy"



set "SETUP_B64_3=SW52YXJpYW50KCkgLW5lICRjbGllbnRTaGExKSB7DQ0KICAkdG1wQ2xpZW50ID0gIiRjbGllbnQuZG93bmxvYWQiDQ0KICBJbnZva2UtV2ViUmVxdWVzdCAtVXNlQmFzaWNQYXJzaW5nIC1VcmkgImh0dHBzOi8vcGlzdG9uLWRhdGEubW9qYW5nLmNvbS92MS9vYmplY3RzLyRjbGllbnRTaGExL2NsaWVudC5qYXIiIC1PdXRGaWxlICR0bXBDbGllbnQNDQogIGlmICgoR2V0LUZpbGVIYXNoICR0bXBDbGllbnQgLUFsZ29yaXRobSBTSEExKS5IYXNoLlRvTG93ZXJJbnZhcmlhbnQoKSAtbmUgJGNsaWVudFNoYTEpIHsgUmVtb3ZlLUl0ZW0gJHRtcENsaWVudCAtRm9yY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWU7IHRocm93ICdDbGllbnQgSkFSIFNIQS0xIG1pc21hdGNoLicgfQ0NCiAgTW92ZS1JdGVtIC1Gb3JjZSAtTGl0ZXJhbFBhdGggJHRtcENsaWVudCAtRGVzdGluYXRpb24gJGNsaWVudA0NCn0NDQoNDQojIERvd25sb2FkIGV2ZXJ5IFdpbmRvd3MtYWxsb3dlZCBsaWJyYXJ5IGZyb20gdGhlIG9mZmljaWFsIG1hbmlmZXN0IGludG8gdGhlIHByaXZhdGUgdHJlZS4NDQojIFRoaXMgaXMgdGhlIHBhcnQgYSBjbGVhbiBpbnN0YWxsIGNhbm5vdCBib3Jyb3cgZnJvbSBhbiBhcmJpdHJhcnkgbGF1bmNoZXIuDQ0KV3JpdGUtT3V0cHV0ICdbUFJPR1JFU1NdIFZlcmlmeWluZy9kb3dubG9hZGluZyBNaW5lY3JhZnQgbGlicmFyaWVzJw0KV3JpdGUtT3V0cHV0ICdbUFJPR1JFU1NdIFZlcmlmeWluZy9kb3dubG9hZGluZyBsaWJyYXJpZXMnCiRsaWJyYXJpZXNSb290ID0gSm9pbi1QYXRoICRwcml2YXRlR2FtZSAnbGlicmFyaWVzJw0NCldyaXRlLU91dHB1dCAnW1BST0dSRVNTXSBMaWJyYXJpZXMgMC8xMTQgLSB2YWxpZGF0aW5nL2Rvd25sb2FkIGNhY2hlJwokbGlicmFyaWVzID0gQCgkbS5saWJyYXJpZXMpDQ0KJGRvd25sb2FkZWQgPSAwOyAkbGlicmFyeUluZGV4ID0gMDsgJGxpYnJhcnlUb3RhbCA9ICRsaWJyYXJpZXMuQ291bnQNDQpmb3JlYWNoICgkbGlicmFyeSBpbiAkbGlicmFyaWVzKSB7DQ0KICAkbGlicmFyeUluZGV4KysNDQogICRydWxlcyA9IEAoJGxpYnJhcnkucnVsZXMgfCBXaGVyZS1PYmplY3QgeyAkbnVsbCAtbmUgJF8gfSkNDQogICRhbGxvd2VkID0gKCRydWxlcy5Db3VudCAtZXEgMCkNDQogIGlmICgkcnVsZXMuQ291bnQgLWd0IDApIHsNDQogICAgJGFsbG93ZWQgPSAkZmFsc2UNDQogICAgZm9yZWFjaCAoJHJ1bGUgaW4gJHJ1bGVzKSB7DQ0KICAgICAgJG9zID0gJHJ1bGUub3MubmFtZQ0NCiAgICAgIGlmICgkcnVsZS5hY3Rpb24gLWVxICdhbGxvdycgLWFuZCAoISRvcyAtb3IgJG9zIC1lcSAnd2luZG93cycpKSB7ICRhbGxvd2VkID0gJHRydWUgfQ0NCiAgICAgIGlmICgkcnVsZS5hY3Rpb24gLWVxICdkaXNhbGxvdycgLWFuZCAkb3MgLWVxICd3aW5kb3dzJykgeyAkYWxsb3dlZCA9ICRmYWxzZSB9DQ0KICAgIH0NDQogIH0NDQogIGlmICghJGFsbG93ZWQgLW9yICEkbGlicmFyeS5kb3dubG9hZHMuYXJ0aWZhY3QpIHsgY29udGludWUgfQ0NCiAgJGFydGlmYWN0ID0gJGxpYnJhcnkuZG93bmxvYWRzLmFydGlmYWN0DQ0KICAkcmVsYXRpdmUgPSBbc3RyaW5nXSRhcnRpZmFjdC5wYXRoDQ0KICBpZiAoW3N0cmluZ106OklzTnVsbE9yV2hpdGVTcGFjZSgkcmVsYXRpdmUpIC1vciAkcmVsYXRpdmUuQ29udGFpbnMoJy4uJykgLW9yIFtJTy5QYXRoXTo6SXNQYXRoUm9vdGVkKCRyZWxhdGl2ZSkpIHsgdGhyb3cgIlVuc2FmZSBsaWJyYXJ5IHBhdGg6ICRyZWxhdGl2ZSIgfQ0NCiAgJHRhcmdldCA9IEpvaW4tUGF0aCAkbGlicmFyaWVzUm9vdCAoJHJlbGF0aXZlIC1yZXBsYWNlICcvJywgJ1wnKQ0NCiAgJHBhcmVudCA9IFNwbGl0LVBhdGggLVBhcmVudCAkdGFyZ2V0DQ0KICBOZXctSXRlbSAtSXRlbVR5cGUgRGlyZWN0b3J5IC1Gb3JjZSAtUGF0aCAkcGFyZW50IHwgT3V0LU51bGwNDQogIGlmICghKFRlc3QtUGF0aCAkdGFyZ2V0KSAtb3IgKEdldC1GaWxlSGFzaCAkdGFyZ2V0IC1BbGdvcml0aG0gU0hBMSkuSGFzaC5Ub0xvd2VySW52YXJpYW50KCkgLW5lIChbc3RyaW5nXSRhcnRpZmFjdC5zaGExKS5Ub0xvd2VySW52YXJpYW50KCkpIHsNDQogICAgaWYgKENvcHktVmVy"



set "SETUP_B64_4=aWZpZWRGcm9tU291cmNlICR0YXJnZXQgJHJlbGF0aXZlIChbc3RyaW5nXSRhcnRpZmFjdC5zaGExKSkgeyBjb250aW51ZSB9CiAgICAkdG1wTGlicmFyeSA9ICIkdGFyZ2V0LmRvd25sb2FkIg0NCiAgICBJbnZva2UtV2ViUmVxdWVzdCAtVXNlQmFzaWNQYXJzaW5nIC1VcmkgJGFydGlmYWN0LnVybCAtT3V0RmlsZSAkdG1wTGlicmFyeQ0NCiAgICBpZiAoKEdldC1GaWxlSGFzaCAkdG1wTGlicmFyeSAtQWxnb3JpdGhtIFNIQTEpLkhhc2guVG9Mb3dlckludmFyaWFudCgpIC1uZSAoW3N0cmluZ10kYXJ0aWZhY3Quc2hhMSkuVG9Mb3dlckludmFyaWFudCgpKSB7IFJlbW92ZS1JdGVtICR0bXBMaWJyYXJ5IC1Gb3JjZSAtRXJyb3JBY3Rpb24gU2lsZW50bHlDb250aW51ZTsgdGhyb3cgIkxpYnJhcnkgU0hBLTEgbWlzbWF0Y2g6ICRyZWxhdGl2ZSIgfQ0NCiAgICBNb3ZlLUl0ZW0gLUZvcmNlIC1MaXRlcmFsUGF0aCAkdG1wTGlicmFyeSAtRGVzdGluYXRpb24gJHRhcmdldA0NCiAgICAkZG93bmxvYWRlZCsrDQ0KICB9DQ0KICBpZiAoKCRsaWJyYXJ5SW5kZXggJSA1KSAtZXEgMCAtb3IgJGxpYnJhcnlJbmRleCAtZXEgJGxpYnJhcnlUb3RhbCkgeyAkbGlicmFyeVBjdD1baW50XSgxMDAqJGxpYnJhcnlJbmRleC8kbGlicmFyeVRvdGFsKTsgV3JpdGUtT3V0cHV0ICJbUFJPR1JFU1NdIExpYnJhcmllcyAkbGlicmFyeUluZGV4LyRsaWJyYXJ5VG90YWwgKCRsaWJyYXJ5UGN0JSkiIH0NDQp9DQ0KV3JpdGUtT3V0cHV0ICJbSU5GT10gVmVyaWZpZWQgTWluZWNyYWZ0IGxpYnJhcmllczogJCgkbGlicmFyaWVzLkNvdW50KTsgZG93bmxvYWRlZDogJGRvd25sb2FkZWQiDQ0KDQ0KIyBGZXRjaCB0aGUgb2ZmaWNpYWwgYXNzZXQgaW5kZXggYW5kIGV2ZXJ5IGNvbnRlbnQtYWRkcmVzc2VkIG9iamVjdCwgc28gcHJlcGFyYXRpb24gaXMgaW5kZXBlbmRlbnQNDQojIG9mIHRoZSBzb3VyY2UgbGF1bmNoZXIncyBtdXRhYmxlIGFzc2V0IGNhY2hlIHRvby4NDQpXcml0ZS1PdXRwdXQgJ1tQUk9HUkVTU10gVmVyaWZ5aW5nL2Rvd25sb2FkaW5nIE1pbmVjcmFmdCBhc3NldHMnDQpXcml0ZS1PdXRwdXQgJ1tQUk9HUkVTU10gVmVyaWZ5aW5nL2Rvd25sb2FkaW5nIGFzc2V0cycKJGFzc2V0SW5kZXggPSAkbS5hc3NldEluZGV4DQ0KaWYgKCEkYXNzZXRJbmRleC51cmwgLW9yICEkYXNzZXRJbmRleC5zaGExIC1vciAhJGFzc2V0SW5kZXguaWQpIHsgdGhyb3cgJ09mZmljaWFsIG1hbmlmZXN0IGhhcyBubyB2YWxpZCBhc3NldEluZGV4IGRlc2NyaXB0b3IuJyB9DQ0KJGFzc2V0Um9vdCA9IEpvaW4tUGF0aCAkcHJpdmF0ZUdhbWUgJ2Fzc2V0cycNDQokaW5kZXhlcyA9IEpvaW4tUGF0aCAkYXNzZXRSb290ICdpbmRleGVzJw0NCiRvYmplY3RzID0gSm9pbi1QYXRoICRhc3NldFJvb3QgJ29iamVjdHMnDQ0KTmV3LUl0ZW0gLUl0ZW1UeXBlIERpcmVjdG9yeSAtRm9yY2UgLVBhdGggJGluZGV4ZXMsJG9iamVjdHMgfCBPdXQtTnVsbA0NCiRpbmRleFBhdGggPSBKb2luLVBhdGggJGluZGV4ZXMgKCRhc3NldEluZGV4LmlkICsgJy5qc29uJykNDQppZiAoIShUZXN0LVBhdGggJGluZGV4UGF0aCkgLW9yIChHZXQtRmlsZUhhc2ggJGluZGV4UGF0aCAtQWxnb3JpdGhtIFNIQTEpLkhhc2guVG9Mb3dlckludmFyaWFudCgpIC1uZSAkYXNzZXRJbmRleC5zaGExLlRvTG93ZXJJbnZhcmlhbnQoKSkgew0NCiAgJHRtcEluZGV4ID0gIiRpbmRleFBhdGguZG93bmxvYWQiDQ0KICBJbnZva2UtV2ViUmVxdWVzdCAtVXNlQmFzaWNQYXJzaW5nIC1VcmkgJGFzc2V0SW5kZXgudXJsIC1PdXRGaWxlICR0bXBJbmRleA0NCiAgaWYgKChHZXQtRmlsZUhhc2ggJHRtcEluZGV4IC1BbGdvcml0aG0gU0hBMSkuSGFzaC5Ub0xvd2VySW52YXJpYW50KCkgLW5lICRhc3NldEluZGV4LnNoYTEuVG9Mb3dlckludmFyaWFudCgpKSB7IFJlbW92ZS1JdGVtICR0bXBJbmRleCAtRm9yY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWU7IHRocm93ICdBc3NldCBpbmRleCBTSEEtMSBtaXNtYXRjaC4nIH0NDQogIE1vdmUtSXRlbSAtRm9yY2UgJHRtcEluZGV4ICRpbmRleFBhdGgNDQp9DQ0KJGluZGV4RGF0YSA9IEdldC1Db250ZW50IC1SYXcgLUxpdGVyYWxQ"



set "SETUP_B64_5=YXRoICRpbmRleFBhdGggfCBDb252ZXJ0RnJvbS1Kc29uDQ0KJG9iamVjdENvdW50ID0gMDsgJG9iamVjdEJ5dGVzID0gMEw7ICRhc3NldFRvdGFsID0gQCgkaW5kZXhEYXRhLm9iamVjdHMuUFNPYmplY3QuUHJvcGVydGllcykuQ291bnQNDQpmb3JlYWNoICgkZW50cnkgaW4gJGluZGV4RGF0YS5vYmplY3RzLlBTT2JqZWN0LlByb3BlcnRpZXMpIHsNDQogICRoYXNoID0gKFtzdHJpbmddJGVudHJ5LlZhbHVlLmhhc2gpLlRvTG93ZXJJbnZhcmlhbnQoKQ0NCiAgaWYgKCRoYXNoIC1ub3RtYXRjaCAnXlswLTlhLWZdezQwfSQnKSB7IHRocm93ICJVbnNhZmUgYXNzZXQgaGFzaCBmb3IgJCgkZW50cnkuTmFtZSkiIH0NDQogICRvYmplY3QgPSBKb2luLVBhdGggKEpvaW4tUGF0aCAkb2JqZWN0cyAkaGFzaC5TdWJzdHJpbmcoMCwyKSkgJGhhc2gNDQogIGlmICghKFRlc3QtUGF0aCAkb2JqZWN0KSAtb3IgKEdldC1GaWxlSGFzaCAkb2JqZWN0IC1BbGdvcml0aG0gU0hBMSkuSGFzaC5Ub0xvd2VySW52YXJpYW50KCkgLW5lICRoYXNoKSB7DQ0KICAgIE5ldy1JdGVtIC1JdGVtVHlwZSBEaXJlY3RvcnkgLUZvcmNlIC1QYXRoIChTcGxpdC1QYXRoIC1QYXJlbnQgJG9iamVjdCkgfCBPdXQtTnVsbA0NCiAgICAkc291cmNlUmVsYXRpdmUgPSAiYXNzZXRzL29iamVjdHMvJCgkaGFzaC5TdWJzdHJpbmcoMCwyKSkvJGhhc2giCiAgICBpZiAoQ29weS1WZXJpZmllZEZyb21Tb3VyY2UgJG9iamVjdCAkc291cmNlUmVsYXRpdmUgJGhhc2gpIHsgJG9iamVjdENvdW50Kys7IGNvbnRpbnVlIH0KICAgICR0bXBPYmplY3QgPSAiJG9iamVjdC5kb3dubG9hZCINDQogICAgSW52b2tlLVdlYlJlcXVlc3QgLVVzZUJhc2ljUGFyc2luZyAtVXJpICJodHRwczovL3Jlc291cmNlcy5kb3dubG9hZC5taW5lY3JhZnQubmV0LyQoJGhhc2guU3Vic3RyaW5nKDAsMikpLyRoYXNoIiAtT3V0RmlsZSAkdG1wT2JqZWN0DQ0KICAgIGlmICgoR2V0LUZpbGVIYXNoICR0bXBPYmplY3QgLUFsZ29yaXRobSBTSEExKS5IYXNoLlRvTG93ZXJJbnZhcmlhbnQoKSAtbmUgJGhhc2gpIHsgUmVtb3ZlLUl0ZW0gJHRtcE9iamVjdCAtRm9yY2UgLUVycm9yQWN0aW9uIFNpbGVudGx5Q29udGludWU7IHRocm93ICJBc3NldCBTSEEtMSBtaXNtYXRjaDogJCgkZW50cnkuTmFtZSkiIH0NDQogICAgTW92ZS1JdGVtIC1Gb3JjZSAkdG1wT2JqZWN0ICRvYmplY3QNDQogICAgJG9iamVjdEJ5dGVzICs9IFtsb25nXSRlbnRyeS5WYWx1ZS5zaXplDQ0KICB9DQ0KICAkb2JqZWN0Q291bnQrKw0NCiAgaWYgKCgkb2JqZWN0Q291bnQgJSAxMDApIC1lcSAwIC1vciAkb2JqZWN0Q291bnQgLWVxICRhc3NldFRvdGFsKSB7ICRhc3NldFBjdD1baW50XSgxMDAqJG9iamVjdENvdW50LyRhc3NldFRvdGFsKTsgV3JpdGUtT3V0cHV0ICJbUFJPR1JFU1NdIEFzc2V0cyAkb2JqZWN0Q291bnQvJGFzc2V0VG90YWwgKCRhc3NldFBjdCUpIiB9DQ0KfQ0NCldyaXRlLU91dHB1dCAiW0lORk9dIFZlcmlmaWVkIGFzc2V0IG9iamVjdHM6ICRvYmplY3RDb3VudDsgbmV3bHkgZG93bmxvYWRlZCBieXRlczogJG9iamVjdEJ5dGVzIg0NCg0NCiRzZXJ2ZXIgPSBKb2luLVBhdGggJGRpciAnc2VydmVyLmphcicKaWYgKCEoVGVzdC1QYXRoICRzZXJ2ZXIpIC1vciAoR2V0LUZpbGVIYXNoICRzZXJ2ZXIgLUFsZ29yaXRobSBTSEExKS5IYXNoLlRvTG93ZXJJbnZhcmlhbnQoKSAtbmUgJHNlcnZlclNoYTEpIHsKICAkc2VydmVyUmV1c2VkID0gQ29weS1WZXJpZmllZEZyb21Tb3VyY2UgJHNlcnZlciAndmVyc2lvbnMvMjYuMy9zZXJ2ZXIuamFyJyAkc2VydmVyU2hhMQogIGlmICghJHNlcnZlclJldXNlZCkgewogICAgJHRtcFNlcnZlciA9ICIkc2VydmVyLmRvd25sb2FkIgogICAgdHJ5IHsKICAgICAgSW52b2tlLVdlYlJlcXVlc3QgLVVzZUJhc2ljUGFyc2luZyAtVXJpICRzZXJ2ZXJVcmwgLU91dEZpbGUgJHRtcFNlcnZlcgogICAgICBpZiAoKEdldC1GaWxlSGFzaCAkdG1wU2VydmVyIC1BbGdvcml0aG0gU0hBMSkuSGFzaC5Ub0xvd2VySW52YXJpYW50KCkgLW5lICRzZXJ2ZXJTaGExKSB7IHRocm93ICdTZXJ2ZXIgSkFSIFNIQS0xIG1pc21hdGNoLicgfQogICAgICBNb3ZlLUl0ZW0gLUZv"



set "SETUP_B64_6=cmNlIC1MaXRlcmFsUGF0aCAkdG1wU2VydmVyIC1EZXN0aW5hdGlvbiAkc2VydmVyCiAgICB9IGNhdGNoIHsgUmVtb3ZlLUl0ZW0gLUxpdGVyYWxQYXRoICR0bXBTZXJ2ZXIgLUZvcmNlIC1FcnJvckFjdGlvbiBTaWxlbnRseUNvbnRpbnVlOyB0aHJvdyB9CiAgfQp9CgojIFJlc29sdmUgdGhlIHByZWNpc2UgSkRLIHBhY2thZ2UgYW5kIG1hdGNoaW5nIFNIQS0yNTYgZnJvbSB0aGUgc2FtZSBBZG9wdGl1bSBtZXRhZGF0YSByZXNwb25zZS4NDQpXcml0ZS1PdXRwdXQgJ1tQUk9HUkVTU10gVmVyaWZ5aW5nL2luc3RhbGxpbmcgSmF2YSAyNScNCldyaXRlLU91dHB1dCAnW1BST0dSRVNTXSBWZXJpZnlpbmcvaW5zdGFsbGluZyBKYXZhIDI1JwokbWV0YWRhdGFVcmwgPSAnaHR0cHM6Ly9hcGkuYWRvcHRpdW0ubmV0L3YzL2Fzc2V0cy9sYXRlc3QvMjUvaG90c3BvdD9hcmNoaXRlY3R1cmU9eDY0JmltYWdlX3R5cGU9amRrJm9zPXdpbmRvd3MmdmVuZG9yPWVjbGlwc2UnDQ0KJHJlbGVhc2UgPSAoSW52b2tlLVJlc3RNZXRob2QgLVVzZUJhc2ljUGFyc2luZyAtVXJpICRtZXRhZGF0YVVybCB8IFNlbGVjdC1PYmplY3QgLUZpcnN0IDEpDQ0KJHBrZyA9ICRyZWxlYXNlLmJpbmFyeS5wYWNrYWdlDQ0KaWYgKCRyZWxlYXNlLnZlcnNpb24ubWFqb3IgLW5lIDI1IC1vciAhJHBrZy5saW5rIC1vciAhJHBrZy5jaGVja3N1bSkgeyB0aHJvdyAnQWRvcHRpdW0gZGlkIG5vdCByZXR1cm4gYSB2YWxpZCBXaW5kb3dzIHg2NCBKREsgMjUgcGFja2FnZS4nIH0NDQokcnVudGltZSA9IEpvaW4tUGF0aCAkUm9vdCAnLmxvY2FsL3J1bnRpbWUnDQ0KJGpkayA9IEpvaW4tUGF0aCAkcnVudGltZSAnamRrLTI1Jw0NCiRqYXZhID0gSm9pbi1QYXRoICRqZGsgJ2Jpbi9qYXZhLmV4ZScNDQokamF2YWMgPSBKb2luLVBhdGggJGpkayAnYmluL2phdmFjLmV4ZScNDQppZiAoIShUZXN0LVBhdGggJGphdmEpIC1vciAhKFRlc3QtUGF0aCAkamF2YWMpKSB7DQ0KICBOZXctSXRlbSAtSXRlbVR5cGUgRGlyZWN0b3J5IC1Gb3JjZSAtUGF0aCAkcnVudGltZSB8IE91dC1OdWxsDQ0KICAkemlwID0gSm9pbi1QYXRoICRydW50aW1lICdqZGsyNS5kb3dubG9hZC56aXAnDQ0KICAkZXh0cmFjdCA9IEpvaW4tUGF0aCAkcnVudGltZSAnamRrMjUudW5wYWNrJw0NCiAgV3JpdGUtT3V0cHV0ICJbSU5GT10gRG93bmxvYWRpbmcgVGVtdXJpbiBKREsgJCgkcmVsZWFzZS52ZXJzaW9uLnNlbXZlcikiDQ0KICBJbnZva2UtV2ViUmVxdWVzdCAtVXNlQmFzaWNQYXJzaW5nIC1VcmkgJHBrZy5saW5rIC1PdXRGaWxlICR6aXANDQogICRhY3R1YWwgPSAoR2V0LUZpbGVIYXNoIC1MaXRlcmFsUGF0aCAkemlwIC1BbGdvcml0aG0gU0hBMjU2KS5IYXNoLlRvTG93ZXJJbnZhcmlhbnQoKQ0NCiAgaWYgKCRhY3R1YWwgLW5lICRwa2cuY2hlY2tzdW0uVG9Mb3dlckludmFyaWFudCgpKSB7IHRocm93ICJKREsgU0hBLTI1NiBtaXNtYXRjaDogZ290ICRhY3R1YWwsIGV4cGVjdGVkICQoJHBrZy5jaGVja3N1bSkiIH0NDQogIGlmIChUZXN0LVBhdGggJGV4dHJhY3QpIHsgUmVtb3ZlLUl0ZW0gJGV4dHJhY3QgLVJlY3Vyc2UgLUZvcmNlIH0NDQogIEV4cGFuZC1BcmNoaXZlIC1MaXRlcmFsUGF0aCAkemlwIC1EZXN0aW5hdGlvblBhdGggJGV4dHJhY3QgLUZvcmNlDQ0KICAkdG9wID0gR2V0LUNoaWxkSXRlbSAkZXh0cmFjdCAtRGlyZWN0b3J5IHwgU2VsZWN0LU9iamVjdCAtRmlyc3QgMQ0NCiAgaWYgKCEkdG9wKSB7IHRocm93ICdKREsgYXJjaGl2ZSBoYXMgbm8gdG9wLWxldmVsIGRpcmVjdG9yeS4nIH0NDQogIGlmIChUZXN0LVBhdGggJGpkaykgeyBSZW1vdmUtSXRlbSAkamRrIC1SZWN1cnNlIC1Gb3JjZSB9DQ0KICBNb3ZlLUl0ZW0gJHRvcC5GdWxsTmFtZSAkamRrDQ0KICBSZW1vdmUtSXRlbSAkZXh0cmFjdCAtUmVjdXJzZSAtRm9yY2UNDQp9DQ0KaWYgKCEoVGVzdC1QYXRoICRqYXZhKSAtb3IgIShUZXN0LVBhdGggJGphdmFjKSkgeyB0aHJvdyAnSkRLIDI1IGphdmEuZXhlIG9yIGphdmFjLmV4ZSBpcyBtaXNzaW5nIGFmdGVyIGluc3RhbGxhdGlvbi4nIH0NDQojIENhcHR1cmUgbmF0aXZlIHN0ZGVyciBzYWZlbHk7IFBvd2VyU2hlbGwgdHJlYXRzIGphdmEgLXZl"



set "SETUP_B64_7=cnNpb24ncyBzdGRlcnIgYXMgYW4gZXJyb3IgcmVjb3JkLg0NCiRwc2kgPSBbRGlhZ25vc3RpY3MuUHJvY2Vzc1N0YXJ0SW5mb106Om5ldygpDQ0KJHBzaS5GaWxlTmFtZSA9ICRqYXZhOyAkcHNpLkFyZ3VtZW50cyA9ICctdmVyc2lvbic7ICRwc2kuVXNlU2hlbGxFeGVjdXRlID0gJGZhbHNlDQ0KJHBzaS5SZWRpcmVjdFN0YW5kYXJkRXJyb3IgPSAkdHJ1ZTsgJHBzaS5SZWRpcmVjdFN0YW5kYXJkT3V0cHV0ID0gJHRydWUNDQokcCA9IFtEaWFnbm9zdGljcy5Qcm9jZXNzXTo6U3RhcnQoJHBzaSk7ICRvdXQgPSAkcC5TdGFuZGFyZE91dHB1dC5SZWFkVG9FbmQoKSArICRwLlN0YW5kYXJkRXJyb3IuUmVhZFRvRW5kKCk7ICRwLldhaXRGb3JFeGl0KCkNDQppZiAoJHAuRXhpdENvZGUgLW5lIDAgLW9yICRvdXQgLW5vdG1hdGNoICd2ZXJzaW9uICIyNVwuJykgeyB0aHJvdyAiSW5zdGFsbGVkIEphdmEgaXMgbm90IG1ham9yIHZlcnNpb24gMjU6ICRvdXQiIH0NDQpXcml0ZS1PdXRwdXQgIltPS10gT2ZmaWNpYWwgbWFuaWZlc3QsIGNsaWVudC9zZXJ2ZXIgYXJ0aWZhY3RzLCBhbmQgSmF2YSAyNSBydW50aW1lIGFyZSB2ZXJpZmllZC4iDQ0KV3JpdGUtT3V0cHV0ICJIT1JJWk9OX1BSSVZBVEVfTUlORUNSQUZUX0RJUj0kcHJpdmF0ZUdhbWUiDQ0K"



powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$b=$env:SETUP_B64_1+$env:SETUP_B64_2+$env:SETUP_B64_3+$env:SETUP_B64_4+$env:SETUP_B64_5+$env:SETUP_B64_6+$env:SETUP_B64_7; [IO.File]::WriteAllBytes($env:SETUP_PS1,[Convert]::FromBase64String($b))"



if errorlevel 1 (call :fail 13 "Cannot extract embedded setup helper"& exit /b 13)



powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SETUP_PS1%" -Root "%HROOT%"



set "SETUP_RC=!ERRORLEVEL!"



del "%SETUP_PS1%" 2>nul



if not "!SETUP_RC!"=="0" (call :fail 20 "Setup helper failed; see the error above"& exit /b 20)



if /i "%MODE%"=="verify" (echo [OK] Verified isolated inputs are ready; game not launched.& exit /b 0)



call :progress 4 "Preparing Horizon from isolated official files"



set "JAVA_HOME=%HROOT%\.local\runtime\jdk-25"

if not exist "%JAVA_HOME%\bin\java.exe" set "JAVA_HOME=%ProgramFiles%\Eclipse Adoptium\jdk-25.0.4.101-hotspot"



set "PATH=%JAVA_HOME%\bin;%PATH%"



set "PRIVATE_MCDIR=%HROOT%\.local\minecraft-source\26.3"



"%PREPARE%" --prepare --server-jar "%SERVER%" --minecraft-dir "%PRIVATE_MCDIR%" --root "%HROOT%"



if errorlevel 1 (call :fail 30 "Horizon preparation failed; native exit code !ERRORLEVEL!"& exit /b 30)



echo [INFO] Preparing Minecraft sound assets (this may take a few minutes on the first run).



"%PREPARE%" sounds --minecraft-dir "%PRIVATE_MCDIR%" --root "%HROOT%"



if errorlevel 1 (call :fail 33 "Horizon sound preparation failed; see the error above"& exit /b 33)



if not exist "%RESOURCES%\horizon-resources.json" (call :fail 32 "Prepared resource manifest missing"& exit /b 32)



mkdir "%HROOT%\.local\state" 2>nul



(echo Horizon=%HROOT%&echo Minecraft=26.3&echo Resources=%RESOURCES%&echo Sounds=prepared) >"%READY_MARKER%"



if /i "%MODE%"=="prepare" (echo [OK] Resources prepared and verified; game not launched.& exit /b 0)



:runtime



call :progress 5 "Backing up Horizon saves"



if exist "%HROOT%\saves" (



 set "STAMP=%DATE:/=-%_%TIME::=-%"



 set "STAMP=!STAMP:.=-!"



 set "STAMP=!STAMP: =_!"



 set "BACKUP_TARGET=%BACKUPS%\!STAMP!"



 mkdir "!BACKUP_TARGET!" 2>nul



 robocopy "%HROOT%\saves" "!BACKUP_TARGET!" /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XJ >nul



 set "BACKUP_RC=!ERRORLEVEL!"



 if !BACKUP_RC! GEQ 8 (call :fail 31 "Save backup failed; refusing to continue"& exit /b 31)



)



call :progress 6 "Syncing source worlds"



if defined SAVE_SOURCE if exist "%SAVE_SOURCE%" (



 if not exist "%HROOT%\saves" mkdir "%HROOT%\saves" 2>nul



 robocopy "%SAVE_SOURCE%" "%HROOT%\saves" /E /COPY:DAT /DCOPY:DAT /R:2 /W:1 /XJ >nul



 set "SYNC_RC=!ERRORLEVEL!"



 if !SYNC_RC! GEQ 8 (call :fail 31 "Save sync failed; robocopy code !SYNC_RC!"& exit /b 31)



)



echo [SUMMARY] Horizon: "%HROOT%"



echo [SUMMARY] Minecraft: 26.3



if exist "%READY_MARKER%" echo [SUMMARY] Resources and sounds: prepared



if defined SAVE_SOURCE echo [SUMMARY] Save source: "%SAVE_SOURCE%"



echo [SUMMARY] Mode: %MODE%



call :progress 7 "Launching Horizon Rust client"



pushd "%HROOT%"



"%CLIENT%" --resources "%RESOURCES%"



set "GAME_RC=%ERRORLEVEL%"



if not "%GAME_RC%"=="0" call :fail %GAME_RC% "Horizon client returned an error"



popd



exit /b %GAME_RC%



:progress



set /a "PCT=%~1*100/TOTAL"



set "BAR="



for /l %%N in (1,1,20) do if %%N LEQ %~1 set "BAR=!BAR!#"



for /l %%N in (1,1,20) do if %%N GTR %~1 set "BAR=!BAR!-"



echo.



echo [!BAR!] !PCT!%%  %~2



call :log INFO "Stage %~1/%TOTAL%: %~2"



exit /b 0



:log



set "LOG_LEVEL=%~1"



set "LOG_MSG=%*"



echo [%DATE% %TIME%] [%LOG_LEVEL%] %LOG_MSG%



exit /b 0



:fail



set "FAIL_RC=%~1"



call :log ERROR %*



echo [ERROR] %*



exit /b %FAIL_RC%

