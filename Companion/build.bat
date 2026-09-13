@echo off
setlocal
cd /d "%~dp0"

echo ===================================================
echo Building Akimbo Companion (Standalone Executable)
echo ===================================================

set "CSC=%SystemRoot%\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if not exist "%CSC%" (
    set "CSC=%SystemRoot%\Microsoft.NET\Framework\v4.0.30319\csc.exe"
)

if not exist "%CSC%" (
    echo [ERROR] Microsoft .NET Framework C# compiler was not found.
    pause
    exit /b 1
)

set "OUT=%~dp0Akimbo.exe"
set "SRC=%~dp0Source\Program.cs"
set "MANIFEST=%~dp0Source\app.manifest"
set "ICO=%~dp0..\Media\akimbo-logo.ico"
set "PNG=%~dp0..\Media\akimbo-logo.png"

echo Compiling %OUT% ...

"%CSC%" /target:winexe /optimize+ /platform:anycpu /out:"%OUT%" /win32icon:"%ICO%" /win32manifest:"%MANIFEST%" /resource:"%PNG%",Akimbo.Companion.Resources.akimbo-logo.png /resource:"%ICO%",Akimbo.Companion.Resources.akimbo-logo.ico /r:System.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll "%SRC%"

if %ERRORLEVEL% equ 0 (
    echo ===================================================
    echo [SUCCESS] Akimbo.exe built successfully!
    echo ===================================================
) else (
    echo ===================================================
    echo [FAILED] Compilation failed with error code %ERRORLEVEL%
    echo ===================================================
    pause
)