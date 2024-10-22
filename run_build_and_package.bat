@echo off
REM Get the directory of the batch file
set SCRIPT_DIR=%~dp0

REM Run build.tcl using relative path
echo Running build.tcl...
call "C:\Xilinx\Vivado\2024.1\bin\vivado.bat" -mode batch -source "%SCRIPT_DIR%build.tcl"

REM Check if the first command was successful
if %errorlevel% neq 0 (
    echo Build failed, aborting.
    pause
    exit /b %errorlevel%
)

REM Run package_ip.tcl using relative path
echo Running package_ip.tcl...
call "C:\Xilinx\Vivado\2024.1\bin\vivado.bat" -mode batch -source "%SCRIPT_DIR%package_ip.tcl"

REM Check if the second command was successful
if %errorlevel% neq 0 (
    echo Packaging failed, aborting.
    pause
    exit /b %errorlevel%
)

echo Both scripts ran successfully.
pause
