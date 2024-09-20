@echo off
mode 70,30
REM mode con:cols=70 lines=3000
setlocal enabledelayedexpansion

REM INITIATION_SECTION

:: CHECK_ADMIN
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: ACTIVATE_ADMIN
if '%errorlevel%' NEQ '0' (
echo Requesting Administrative privileges...
goto ADMIN_PROMPT
)
echo Administrator mode Active...
echo.
echo.
goto CHANGE_DIR

:: CHECK_AND_CREATE_DOWNLOADS
if not exist "%~dp0Downloads" (
    echo Downloads folder not found. Creating it now...
    mkdir "%~dp0Downloads"
) else (
    echo Downloads folder already exists.
)
echo.
echo.

:ADMIN_PROMPT
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B

:CHANGE_DIR
del "%temp%\getadmin.vbs"
pushd "%CD%"
CD /D "%~dp0"
echo Working directory set... 
echo.
echo.

REM APPLICATION_SECTION

:: ASCII_ART/INTRO/READ_RETRIES
cls
echo.
echo "   ________                      .____                    .___"
echo "   \______ \   ______  _  ______ |    |    ___________  __| _/"
echo "    |    |  \ /  _ \ \/ \/ /    \|    |   /  _ \_  __ \/ __ | "
echo "    |    \   (  <_> )     /   |  \    |__(  <_> )  | \/ /_/ | "
echo "    /______  /\____/ \/\_/|___|  /_______ \____/|__|  \____ | "
echo "           \/                  \/        \/                \/ "
echo.
for /f "delims=" %%a in ('powershell -command "$config = Import-PowerShellDataFile -Path 'config.psd1'; $config['retries']"') do set "max_retries=%%a"
set "message=We will now insist upon Downloading your files %max_retries% times..."
set "delay=1"
for %%a in (%message%) do (
echo|set /p="%%a "
timeout /t %delay% /nobreak >nul
)
echo.
echo.

:: EXECUTE_MAIN
@echo on
powershell -ExecutionPolicy Bypass -File main.ps1
@echo off
echo.
echo.

REM OUTRO_SECTION

:: ENDING
set "message=Remember to move Completed Files to Intended Destinations..."
set "delay=1"
for %%a in (%message%) do (
echo|set /p="%%a "
timeout /t %delay% /nobreak >nul
)
echo.
echo.

:EXIT
set /p input=(Press Enter to Finish...)
