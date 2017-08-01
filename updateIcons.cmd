pushd %~dp0
@echo off

setlocal enabledelayedexpansion
set folderName=
set storeType=
set serverName=notSet
set errorlog=errors.txt
set successlog=success.log
set timeoutlog=timeout.log
set pseUser=ridenow\psexecUser
set psePass=bxCpPZyPkgxU9aU8
set roboOptions=/R:2 /W:10 /NDL /NP


set description=Updating Icons only
if defined description set description=^(%description%^)
set /p hostnameFile="Enter name of hostname file to use: "
if /i %hostnameFile:~-4% NEQ .txt set hostnameFile=%hostnameFile%.txt
set successlog=OK-%hostnameFile:~0,-4%.log
if not exist %hostnameFile% (
  echo.
  echo I can't find the file "%hostnameFile%" containing a list of hostnames.
  echo Please create a file containing one computer name per line, with no header
  echo or other text in the file. The file can be given a desciptive name
  echo ^("%hostnameFile%" in this example^) and placed in the same folder as
  echo %~nx0. See example.txt to get started.
  pause
  goto :EOF
)
rem if defined description set description=for %description%
echo. >> %successlog%
echo Starting batch on !date! !time! %description% >> %successlog%
rem if not exist %errorlog% (
rem  echo Hostname,Error,Time,Pass >> %errorlog%
rem  echo ,-1073741819,,,Success but unknown >> %errorlog%
rem  echo ,1722,,,Network path not found >> %errorlog%
rem  echo ,5,,,Access denied >> %errorlog%
rem  echo ,1460,,,Timeout >> %errorlog%
rem )
rem echo. >> %errorlog%
rem echo Starting batch on !date! !time! %description% >> %errorlog%

set serverName=%hostnameFile:~0,4%SERVER
call pingHost.cmd %serverName%
if errorlevel == 1 set serverName=WILLISSERVER
if errorlevel == 2 set serverName=WILLISSERVER
set serverName
FOR /F %%i IN (%hostnameFile%) DO (
call pingHost.cmd %%i %ipOctet%
if !errorlevel! EQU 0 (
  echo ******** Updating icons on %%i ********

    call :main %%i Metric LightspeedEVO
    call :main %%i Harley LightspeedEVO-HD
    call :main %%i MeTest LightspeedEVO-TestMetric
    call :main %%i HDTest LightspeedEVO-TestHD

) else if !errorlevel! equ 4 (
    echo %%i is not in the %ipOctet% network && echo %%i is not in the %ipOctet% network >> %timeoutlog%
  ) else echo %%i is offline && echo %%i is offline !date! !time! >> %timeoutlog% 
)

del %temp%\search 2> nul
echo Finished processing at !time! >> %successlog%
pause
start notepad %~dp0\%successlog%
exit /b

:main
set pc=%1
set storeType=%2
set folderName=%3
rem icacls LightspeedEVO-NV07 /grant RIDENOW\Domain Users:(OI)(CI)(M) /t

  if exist "\\%pc%\c$\Program Files (x86)" (
    set pgmFiles=Program Files ^(x86^)\%folderName%
    set type=64-bit
  ) else (
    rem path not found, so lets try 32 bit...
    set pgmFiles=Program Files\%folderName%
    set type=32-bit
  )


if not exist \\%pc%\c$\!pgmFiles! exit /b
set source=\\%serverName%\Support Files\EVO\%folderName%
set iconFile=C:\!pgmFiles!\ls.ico
if %storeType:~-4% EQU Test set iconFile=C:\Support\lswhite.ico
rem @echo storetype=%storetype%
rem @echo foldername=%foldername%
rem echo pgmfiles !pgmfiles!
rem echo $pgmfiles %pgmfiles%
rem echo filename=%filename%
if not exist "\\%pc%\C$\%pgmFiles%" md "\\%pc%\C$\%pgmFiles%"
if not exist "\\%pc%\c$\Support" mkdir "\\%pc%\C$\Support"
:: Copy lswhite icon to C:\support if it doesnt already exist.
rem if not exist \\%pc%\C$\Support\lswhite.ico psexec \\%pc% -u %pseUser% -p %psePass% -e -n 10 -nobanner cmd /c  copy "%source%\..\Support Files\lswhite.ico" "C:\Support"
if not exist \\%pc%\C$\Support\lswhite.ico copy "%source%\..\Support Files\lswhite.ico" "\\%pc%\C$\Support"
  rem the next line appends all characters from folderName after the 13th char (after "EVO")
  rem this is so we can create the shortcut name with a space in it.
  set filename=Lightspeed EVO%folderName:~13%.lnk
  echo Creating shortcut for !filename!
  call shortcutJS.bat -linkfile "\\%pc%\C$\Users\Public\Desktop\!filename!" -target "C:\!pgmFiles!\Lightspeed.bat" -workingdirectory "C:\!pgmFiles!" -windowstyle 7 -iconlocation "%iconFile%",0 -description "Lightspeed Dealer Management System"
  echo !type! %storeType% file copy to %pc% at !time!  >> %successlog%
exit /b

