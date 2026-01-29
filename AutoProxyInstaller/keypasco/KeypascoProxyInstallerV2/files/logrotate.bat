@echo off
for /f "skip=1 delims=" %%x in ('wmic os get localdatetime') do if not defined X set X=%%x
set yyyyMMdd=%x:~0,8%
cd C:\Keypasco\Log\IisCheckLog
ren apppool.txt apppool_%yyyyMMdd%.txt

type NUL > apppool.txt

