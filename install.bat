@echo off
title VLC Extension Installer - Change Speed and Pitch

echo =======================================================
echo     VLC Media Player Extension Installer
echo =======================================================
echo.

:: Define the target directory for VLC extensions
set "TARGET_DIR=%APPDATA%\vlc\lua\extensions"

:: Check if the .lua script exists in the current directory
dir /b *.lua >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] No .lua file found in this folder!
    echo Please make sure you run this file from the extracted ZIP archive.
    goto END
)

:: Create the destination folder if it doesn't exist
if not exist "%TARGET_DIR%" (
    echo Creating VLC extension directory...
    mkdir "%TARGET_DIR%"
)

:: Copy only the plugin script (.lua) and the required interface image (.jpg)
echo Installing extension files to VLC...
xcopy /Y "*.lua" "%TARGET_DIR%\" > nul 2>&1
xcopy /Y "*.jpg" "%TARGET_DIR%\" > nul 2>&1

:: Final check if the files exist in the target directory
if exist "%TARGET_DIR%\*.lua" (
    goto SUCCESS_END
) else (
    goto ERROR_END
)

:SUCCESS_END
echo.
echo =======================================================
echo [SUCCESS] Extension has been successfully installed!
echo =======================================================
echo.
echo Please restart your VLC Media Player.
echo You can find the extension under: View -^> Change Speed and Pitch
goto END

:ERROR_END
echo.
echo [ERROR] An error occurred while copying the files.
goto END

:END
echo.
echo Press any key to close this window...
pause > nul
