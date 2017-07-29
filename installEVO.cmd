pushd %~dp0
@echo off
if not exist hostnames.txt (
  echo I can't find the file containing a list of hostnames. Please
  echo create a file containing hostnames. Each line should contain
  echo only one computer name and there is no header or other text
  echo in the file. The file should be named hostnames.txt and placed
  echo in the same folder as %~nx0. See example.txt to get started.
  pause
  goto :EOF
)

setlocal enabledelayedexpansion
set folderName=
set storeType=
set serverName=notSet
set errorlog=errors.csv
set successlog=success.log
set timeoutlog=timeout.log
set pseUser=ridenow\psexecUser
set psePass=bxCpPZyPkgxU9aU8

echo. >> %successlog%
echo Starting batch on !date! >> %successlog%
if not exist %errorlog% (
 echo Hostname,Error,Time,Pass >> %errorlog%
 echo ,-1073741819,,,Success but unknown >> %errorlog%
 echo ,1722,,,Network path not found >> %errorlog%
 echo ,5,,,Access denied >> %errorlog%
 echo ,1460,,,Timeout >> %errorlog%
)
echo. >> %errorlog%
echo Starting batch on !date! >> %errorlog%

set /p serverName="Server name to copy from (hostname only)? "
call pingHost %serverName%

if errorlevel == 1 echo Server "%serverName%" not found! && pause && goto :eof
if errorlevel == 2 echo Server "%serverName%" not found! && pause && goto :eof
set /p storeType="Is this a Harley-server Store? [Y,N] "
if /i _%storeType% EQU _Y set folderName=LightspeedEVO-HD
if /i _%storeType% EQU _N set folderName=LightspeedEVO

if not defined folderName goto :eof
if /i %storeType% EQU Y set storeType=Harley
if /i %storeType% EQU N set storeType=Metric

set source="\\%serverName%\Support Files\EVO\%folderName%"
rem set source=\\rnssitstorage\software\%folderName%

set /p ipOctet="Enter a unique IP address octet for %serverName:~0,4% (optional) "
rem psexec \\%%i -s -n 10 cmd
set roboOptions=/E /SEC /R:2 /W:10 /NDL 

FOR /F %%i IN (hostnames.txt) DO (

call pingHost.cmd %%i %ipOctet%

if !errorlevel! EQU 0 (
  if exist "\\%%i\c$\Program Files (x86)" (
    set evo=C:\Program Files ^(x86^)\%folderName%
    echo Starting process on %%i

    md "\\%%i\C$\Program Files (x86)\%folderName%"
    psexec \\%%i -s -n 10 -nobanner icacls "!EVO!" /grant Everyone:^(OI^)^(CI^)F 
    psexec \\%%i -u %pseUser% -p %psePass% -e -n 10 -nobanner robocopy %source% "!evo!" * %roboOptions%
    set roboresult=!errorlevel!
    if !roboresult! LEQ 8 (
    rem the next line appends the last three characters from folderName after the 13th char (-HD if it exists)
    set filename=Lightspeed EVO%folderName:~13,3%.lnk
    Shortcut.exe /f:"\\%%i\C$\Users\Public\Desktop\!filename!" /a:c /t:"!evo!\Lightspeed.bat" /w:"!evo!" /r:7 /d:"Lightspeed Dealer Management System" /i:"!evo!\ls.ico",0
    psexec \\%%i -s -n 10 -nobanner icacls "!EVO!" /grant Everyone:^(OI^)^(CI^)F /t /q
    mkdir \\%%i\C$\LSTemp
    psexec \\%%i -s -n 10 -nobanner icacls C:\LSTemp /grant Everyone:^(OI^)^(CI^)F /t /q
    echo 64-bit %storeType% file copy successful to %%i at !time! with result !roboresult! >> %successlog%
    ) else echo %%i,!errorlevel!,!time!,64-bit >> %errorlog%
  ) else (
    rem path not found, so lets try 32 bit...
    set evo=C:\Program Files\%folderName%

    mkdir "\\%%i\C$\Program Files\%folderName%"
    psexec \\%%i -s -n 10 -nobanner icacls "!EVO!" /grant Everyone:^(OI^)^(CI^)F 
    psexec \\%%i -u %pseUser% -p %psePass% -e -n 10 -nobanner robocopy %source% "!evo!" * %roboOptions%
    set roboresult=!errorlevel!
    if !roboresult! LEQ 8 (
      rem the next line appends the last three characters from folderName after the 13th char (-HD if it exists)
      set filename=Lightspeed EVO%folderName:~13,3%.lnk
      Shortcut.exe /f:"\\%%i\C$\Users\Public\Desktop\!filename!" /a:c /t:"!evo!\Lightspeed.bat" /w:"!evo!" /r:7 /d:"Lightspeed Dealer Management System" /i:"!evo!\ls.ico",0
      psexec \\%%i -s -n 10 -nobanner icacls "!EVO!" /grant Everyone:^(OI^)^(CI^)F /t /q
      mkdir \\%%i\C$\LSTemp
      psexec \\%%i -s -n 10 icacls C:\LSTemp /grant Everyone:^(OI^)^(CI^)F /t /q
      echo 32-bit %storeType% file copy successful to %%i at !time! with result !roboresult! >> %successlog%
    ) else echo %%i,!roboresult!,!time!,32-bit >> %errorlog%
  )
) else if !errorlevel! equ 4 (
  echo %%i is not in the %ipOctet% network && echo %%i is not in the %ipOctet% network >> %timeoutlog%


) else echo %%i is offline && echo %%i is offline >> %timeoutlog% 
)

del %temp%\search 2> nul
echo Finished processing at !time! >> %successlog%
pause
start notepad %~dp0\%successlog%

