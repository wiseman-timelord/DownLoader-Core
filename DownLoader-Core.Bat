:: Script: `.\Downloader-Core.Bat`

:: Initialization
@echo off
setlocal enabledelayedexpansion
title Downloader-Core
color 80
echo Initialization Complete.
timeout /t 1 >nul

:: DISPLAY BANNER: START
cls
echo ========================================================================================================================
echo     Downloader-Core
echo ========================================================================================================================
echo.
timeout /t 1 >nul
:: DISPLAY BANNER: END

:: CHECK ADMIN BLOCK, DO NOT, MODIFY or MOVE: START
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Error: Admin Required!
    timeout /t 2 >nul
    echo Right Click, Run As Administrator.
    timeout /t 2 >nul
    goto :end_of_script
)
echo Status: Administrator
timeout /t 1 >nul
:: CHECK ADMIN BLOCK, DO NOT, MODIFY or MOVE: END

:: DP0 TO SCRIPT BLOCK, DO NOT, MODIFY or MOVE: START
set "ScriptDirectory=%~dp0"
set "ScriptDirectory=%ScriptDirectory:~0,-1%"
cd /d "%ScriptDirectory%"
echo Dp0'd to Script.
timeout /t 1 >nul
:: DP0 TO SCRIPT BLOCK, DO NOT, MODIFY or MOVE: END

:: FIND/CREATE FOLDERS: START
if not exist "%~dp0Downloads" (
    echo Created: .\Downloads
    mkdir "%~dp0Downloads"
) else (
    echo Found: .\Downloads
)
timeout /t 1 >nul
if not exist "%~dp0data" (
    mkdir "%~dp0data"
    echo Created directory: .\data
) else (
    echo Found: .\data
)
timeout /t 1 >nul
:: FIND/CREATE FOLDERS: END

:: FIND/CREATE PSD1: START
if not exist "%~dp0data\persistence.psd1" (
    echo File not found: .\data\persistence.psd1
    echo Creating: .\data\persistence.psd1 ...
    (
    echo @^{
    echo     Retries = 10
    echo     Chunk = 4096
    echo     Suppress = 'True'
    echo     FileName_1 = ''
    echo     Url_1 = ''
    echo     FileName_2 = ''
    echo     Url_2 = ''
    echo     FileName_3 = ''
    echo     Url_3 = ''
    echo     FileName_4 = ''
    echo     Url_4 = ''
    echo     FileName_5 = ''
    echo     Url_5 = ''
    echo     FileName_6 = ''
    echo     Url_6 = ''
    echo     FileName_7 = ''
    echo     Url_7 = ''
    echo     FileName_8 = ''
    echo     Url_8 = ''
    echo     FileName_9 = ''
    echo     Url_9 = ''
    echo ^}    
    ) > "%~dp0data\persistence.psd1"
    echo Created file: .\data\persistence.psd1
) else (
    echo File exists: .\data\persistence.psd1
)
timeout /t 1 >nul
:: FIND/CREATE DATA/PSD1: END

:: EXECUTE_MAIN: START
echo.
echo Executing PowerShell-Core Script...
timeout /t 2 /nobreak >nul
@echo on
pwsh -ExecutionPolicy Bypass -File downloader_core.ps1
@echo off
echo.
echo Remember to move Completed Files to Intended Destinations!
echo.
timeout /t 2 /nobreak >nul
:: EXECUTE_MAIN: END

:end_of_script
echo Batch Processes Finished.
echo Exiting Batch Script.
timeout /t 3 /nobreak >nul
echo.
set /p input=(Press Enter to Finish...)
