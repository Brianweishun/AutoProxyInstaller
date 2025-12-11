@echo off

setlocal enabledelayedexpansion

:: need to modify
set sqlPATH=.\files\V1.016.39.1.43.0-all.sql
rem proxy ip address 
set yourIP=10.0.1.147

:: should not modify
set PATH=%PATH%;C:\Program Files\PostgreSQL\16\bin

set yourIP=%1

set keyword=host    all             all             ::1/128                 trust
set newLine=host    all             all             %yourIP%/32           md5

set inputFile=C:\Program Files\PostgreSQL\16\data\pg_hba.conf
set outputFile=C:\Program Files\PostgreSQL\16\data\pg_hba.conf.output
set search=host.*all.*all.*::1/128.*scram-sha-256
set replace=host    all             all             ::1/128                 trust

:: Extract date components
set "YYYY=%LocalDateTime:~0,4%"
set "MM=%LocalDateTime:~4,2%"
set "DD=%LocalDateTime:~6,2%"

:: Extract time components (optional)
set "HH=%LocalDateTime:~8,2%"
set "MIN=%LocalDateTime:~10,2%"
set "SEC=%LocalDateTime:~12,2%"

:: Format the date and time
set "FormattedDate=%YYYY%-%MM%-%DD%"
set "FormattedTime=%HH%%MIN%%SEC%"

set OUTFILESUFFIX=%FormattedDate%.%FormattedTime%
set OUTFILESUFFIX=%date:~0,4%-%date:~5,2%-%date:~8,2%.%time:~0,2%%time:~3,2%%time:~6,2%

REM Count the number of parameters
SET paramCount=%*

IF "%paramCount%"=="" (
    echo No parameters provided:
	echo.
	echo ProxyPostgresSetting.bat proxyIP.
    EXIT /B 1
)

SET /A count=0
FOR %%A IN (%*) DO (
    SET /A count+=1
)

REM Display the number of parameters
REM echo Number of parameters provided: %count%

REM Optional: Perform actions based on the number of parameters
IF %count% NEQ 1 (
    echo Invalid parameters provided:
	echo.
	echo ProxyPostgresSetting.bat proxyIP.
    EXIT /B 1
) ELSE (
    REM echo Valid number of parameters.
)

REM Check if parameters are passed
IF "%1"=="" (
    echo No parameters provided. Please provide valid parameters.
    EXIT /B 1
)

rem backup 
if exist "./backup/pg_hba.conf.ori" (
    copy /y "%inputFile%" "./backup/pg_hba.conf.%OUTFILESUFFIX%"
) else (
    copy /y "%inputFile%" "./backup/pg_hba.conf.ori"
)

::copy /y "%inputFile%" "%outputFile%"

rem modify the authentication method to trust
powershell -Command "(Get-Content '%inputFile%') -replace '%search%', '%replace%' | Set-Content '%inputFile%'"
::echo Replacement complete.

:: Create or overwrite the output file
if exist "%outputFile%" del "%outputFile%"

rem add new line for local ip address
:: Initialize variables
set inserted=0

:: Read input file line by line
for /f "usebackq delims=" %%A in ("%inputFile%") do (
    echo %%A>>"%outputFile%"
    if !inserted! equ 0 (
        echo %%A | findstr /c:"%keyword%" >nul
        if !errorlevel! equ 0 (
            echo %newLine%>>"%outputFile%"
            set inserted=1
        )
    )
)

:: Replace the input file with the modified file
move /y "%outputFile%" "%inputFile%"

echo Line inserted successfully!
rem pause

rem create database and user for proxy
psql -U postgres -c "create user proxyuser;"
psql -U postgres -c "ALTER SYSTEM SET password_encryption = 'md5';"
psql -U postgres -c "SELECT pg_reload_conf();"
psql -U postgres -c "show password_encryption;"
psql -U postgres -c "alter user proxyuser with password 'Test123456';"
psql -U postgres -c "create database proxydb owner proxyuser;"
psql -U postgres -c "grant all privileges on database proxydb to proxyuser;"

rem import sql
psql -U proxyuser -d proxydb -f %sqlPATH%