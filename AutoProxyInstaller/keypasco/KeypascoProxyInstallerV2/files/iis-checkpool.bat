@echo off
set AppPoolName=MFA
set "folderPath=C:\Keypasco\Log\IisCheckLog"

if not exist "%folderPath%" (
    echo Folder not found. Creating...
    mkdir "%folderPath%"
) else (
    echo Folder already exists.
)

REM Get current Date and Time
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set datetime=%datetime:~0,4%-%datetime:~4,2%-%datetime:~6,2% %datetime:~8,2%:%datetime:~10,2%:%datetime:~12,6%

REM Check ApplicationPool status
C:\Windows\System32\inetsrv\appcmd list apppool /name:%AppPoolName% | findstr /c:"state:Started" > nul

if %errorlevel% neq 0 (
  echo [%datetime%] Application Pool %AppPoolName% is not running. Starting it now... >> %folderPath%\apppool.txt
  C:\Windows\System32\inetsrv\appcmd.exe start apppool /apppool.name:%AppPoolName% >> %folderPath%\apppool.txt
) else (
  echo [%datetime%] Application Pool %AppPoolName% is already running. >> %folderPath%\apppool.txt
)

REM Output to log file
echo [%datetime%] Application Pool %AppPoolName% status: %errorlevel% >> %folderPath%\apppool.txt

REM exit