@echo off
:: Display a warning message about the script
echo WARNING: This script will only work if Vivado is installed in the default directory.
echo It is designed to run only on Windows systems.
echo Ensure that the submodule has been loaded before running this script.
echo This script was tested with Vivado v2024.1 (64-bit).
echo.

:: Ask for confirmation
set /p confirm="Do you want to continue? (y/n): "
if /I not "%confirm%"=="y" (
    echo Script aborted.
    exit /b
)

:: Set the relative source folder based on the script's location
set SCRIPT_DIR=%~dp0
set SOURCE=%SCRIPT_DIR%vivado-boards\new\board_files
set TARGET=C:\Xilinx\Vivado\2024.1\data\xhub\boards\XilinxBoardStore\boards\Xilinx

echo Copying files from %SOURCE% to %TARGET%...

:: Check if the script is running with admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Admin rights required. Trying to restart with admin rights...
    powershell -Command "Start-Process '%0' -Verb RunAs"
    exit /b
)

:: Use xcopy to copy all files, including hidden and system files, preserving the directory structure
xcopy "%SOURCE%\*" "%TARGET%" /E /H /I /Y

if %errorLevel% neq 0 (
    echo Failed to copy files.
    exit /b
)

echo Files copied successfully.

:: Provide a final message to test in Vivado's TCL console
echo.
echo To test if everything worked, open the TCL console in Vivado and run the following command:
echo get_board_parts *arty-z7-20*
pause
