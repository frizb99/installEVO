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
set roboOptions=/E /R:2 /W:10 /NDL /XO /NP /log+:C:\Support\EVO-^^!storeType^^!.txt


set /p description="Enter description for log file (optional): "
if defined description set description=^(%description%^)
set /p hostnameFile="Enter name of hostname file to use: "
if /i %hostnameFile:~-4% NEQ .txt set hostnameFile=%hostnameFile%.txt
set successlog=OK-%hostnameFile:~0,-4%.log
set su
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
set /p serverName="Server name to copy from [%serverName%]? "
if %serverName% NEQ x call pingHost %serverName%

if errorlevel == 1 echo Server "%serverName%" not found! && pause && goto :eof
if errorlevel == 2 echo Server "%serverName%" not found! && pause && goto :eof
cls
echo Please select install type:
echo M    Metric ^& Indian EVO
echo H    Harley EVO
echo TM   Test/sandbox EVO for Metric stores
echo TH   Test/sandbox EVO for Harley stores
echo A    All of the above
set /p installType="Install type? [M,H,TM,TH,A]"
if /i _%installType% EQU _M set storeType=Metric && set folderName=LightspeedEVO
if /i _%installType% EQU _H set storeType=Harley && set folderName=LightspeedEVO-HD
if /i _%installType% EQU _TM set storeType=MeTest && set folderName=LightspeedEVO-TestMetric
if /i _%installType% EQU _TH set storeType=HDTest && set folderName=LightspeedEVO-TestHD
if /i _%installType% EQU _A set storeType=All
if not defined storeType goto :eof

call :printStoreIP
set /p ipOctet="Enter a unique IP address octet for %serverName:~0,4% (optional) "

FOR /F %%i IN (%hostnameFile%) DO (
call pingHost.cmd %%i %ipOctet%
if !errorlevel! EQU 0 (
  echo Starting process on %%i
  if %storeType% equ All (
    call :main %%i Metric LightspeedEVO
    call :main %%i Harley LightspeedEVO-HD
    call :main %%i MeTest LightspeedEVO-TestMetric
    call :main %%i HDTest LightspeedEVO-TestHD
  ) else call :main %%i %storeType% %folderName%

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
set iconFile=ls.ico
if %storeType:~-4% EQU Test set iconFile=lswhite.ico
rem icacls LightspeedEVO-NV07 /grant RIDENOW\Domain Users:(OI)(CI)(M) /t

  if exist "\\%pc%\c$\Program Files (x86)" (
    set pgmFiles=Program Files ^(x86^)\%folderName%
    set type=64-bit
  ) else (
    rem path not found, so lets try 32 bit...
    set pgmFiles=Program Files\%folderName%
    set type=32-bit
  )
set source=\\%serverName%\Support Files\EVO\%folderName%
rem @echo storetype=%storetype%
rem @echo foldername=%foldername%
rem echo pgmfiles !pgmfiles!
rem echo $pgmfiles %pgmfiles%
rem echo filename=%filename%
md "\\%pc%\C$\%pgmFiles%"
if not exist \\%pc%\c$\Support mkdir \\%pc%\C$\Support
psexec \\%pc% -s -n 10 -nobanner icacls "C:\!pgmFiles!" /grant "RIDENOW\Domain Users":^(OI^)^(CI^)F 
psexec \\%pc% -u %pseUser% -p %psePass% -e -n 10 -nobanner robocopy "%source%" "C:\!pgmFiles!" * %roboOptions% 

set roboresult=!errorlevel!
if !roboresult! LEQ 7 (
  rem the next line appends all characters from folderName after the 13th char (after "EVO")
  rem this is so we can create the shortcut name with a space in it.
  set filename=Lightspeed EVO%folderName:~13%.lnk
  call shortcutJS.bat -linkfile "\\%pc%\C$\Users\Public\Desktop\!filename!" -target "C:\!pgmFiles!\Lightspeed.bat" -workingdirectory "C:\!pgmFiles!" -windowstyle 7 -iconlocation "C:\!pgmFiles!\%iconFile%",0 -description "Lightspeed Dealer Management System"
  psexec \\%pc% -s -n 10 -nobanner icacls "C:\!pgmFiles!" /grant "RIDENOW\Domain Users":^(OI^)^(CI^)F /t /q
  if not exist \\%pc%\c$\LSTemp mkdir \\%pc%\C$\LSTemp && psexec \\%pc% -s -n 10 -nobanner icacls C:\LSTemp /grant Everyone:^(OI^)^(CI^)F /t /q 
  call :writeSuccess
) else call :writeError
exit /b

:writeSuccess
set description=!roboresult!
if !roboresult! EQU 7 set description=missing files copied. + MISMATCHES + XTRA
if !roboresult! EQU 6 set description=MISMATCHES + XTRA
if !roboresult! EQU 5 set description=missing files copied. + MISMATCHES
if !roboresult! EQU 4 set description=MISMATCHES
if !roboresult! EQU 3 set description=extra files detected in destination. Missing files copied.
if !roboresult! EQU 2 set description=extra files detected in destination. No files copied.
if !roboresult! EQU 1 set description=no errors.
if !roboresult! EQU 0 set description=no changes (files identical)
echo !type! %storeType% file copy to %pc% at !time! completed with %description% >> %successlog%
exit /b

:writeError
set description=!roboresult!
if !roboresult! EQU 16 set description=***FATAL ERROR***
if !roboresult! EQU 15 set description=OKCOPY + FAIL + MISMATCHES + XTRA
if !roboresult! EQU 14 set description=FAIL + MISMATCHES + XTRA
if !roboresult! EQU 13 set description=OKCOPY + FAIL + MISMATCHES
if !roboresult! EQU 12 set description=FAIL + MISMATCHE
if !roboresult! EQU 11 set description=OKCOPY + FAIL + XTRA
if !roboresult! EQU 10 set description=FAIL + XTRA
if !roboresult! EQU 9 set description=OKCOPY + FAIL
if !roboresult! EQU 8 set description=FAIL

echo %pc%-!date!-!time!-"%type%"-%description% >> %errorlog%
exit /b

:printStoreIP

if /i %serverName:~0,4% EQU AZ01 echo IP range for %serverName:~0,4% is 10.26
if /i %serverName:~0,4% EQU RNSS echo IP range for %serverName:~0,4% is 63
if /i %serverName:~0,4% EQU AZ03 echo IP range for %serverName:~0,4% is 50
if /i %serverName:~0,4% EQU AZ04 echo IP range for %serverName:~0,4% is 43
if /i %serverName:~0,4% EQU AZ05 echo IP range for %serverName:~0,4% is 102
if /i %serverName:~0,4% EQU AZ06 echo IP range for %serverName:~0,4% is 46
if /i %serverName:~0,4% EQU AZ07 echo IP range for %serverName:~0,4% is 39
if /i %serverName:~0,4% EQU AZ08 echo IP range for %serverName:~0,4% is 60
if /i %serverName:~0,4% EQU AZ09 echo IP range for %serverName:~0,4% is 38
if /i %serverName:~0,4% EQU AZ10 echo IP range for %serverName:~0,4% is 35
if /i %serverName:~0,4% EQU AZ11 echo IP range for %serverName:~0,4% is 40
if /i %serverName:~0,4% EQU AZ12 echo IP range for %serverName:~0,4% is 48
if /i %serverName:~0,4% EQU AZ13 echo IP range for %serverName:~0,4% is 96
if /i %serverName:~0,4% EQU AZ16 echo IP range for %serverName:~0,4% is 10.143
if /i %serverName:~0,4% EQU AZ17 echo IP range for %serverName:~0,4% is 62
if /i %serverName:~0,4% EQU CA01 echo IP range for %serverName:~0,4% is 101
if /i %serverName:~0,4% EQU FL01 echo IP range for %serverName:~0,4% is 122
if /i %serverName:~0,4% EQU FL07 echo IP range for %serverName:~0,4% is 220
if /i %serverName:~0,4% EQU FL08 echo IP range for %serverName:~0,4% is 124
if /i %serverName:~0,4% EQU FL09 echo IP range for %serverName:~0,4% is 10.224
if /i %serverName:~0,4% EQU FLW1 echo IP range for %serverName:~0,4% is 10.64.8
if /i %serverName:~0,4% EQU KS01 echo IP range for %serverName:~0,4% is 210
if /i %serverName:~0,4% EQU NC01 echo IP range for %serverName:~0,4% is 103.103
if /i %serverName:~0,4% EQU NV01 echo IP range for %serverName:~0,4% is 105
if /i %serverName:~0,4% EQU NV03 echo IP range for %serverName:~0,4% is 41
if /i %serverName:~0,4% EQU NV04 echo IP range for %serverName:~0,4% is 44
if /i %serverName:~0,4% EQU NV06 echo IP range for %serverName:~0,4% is 240
if /i %serverName:~0,4% EQU NV07 echo IP range for %serverName:~0,4% is 10.36
if /i %serverName:~0,4% EQU TX01 echo IP range for %serverName:~0,4% is 56
if /i %serverName:~0,4% EQU TX02 echo IP range for %serverName:~0,4% is 55
if /i %serverName:~0,4% EQU TX03 echo IP range for %serverName:~0,4% is 103.100
if /i %serverName:~0,4% EQU TXW1 echo IP range for %serverName:~0,4% is 103.100
if /i %serverName:~0,4% EQU WA01 echo IP range for %serverName:~0,4% is 200
if /i %serverName:~0,4% EQU OR01 echo IP range for %serverName:~0,4% is 10.222.10

exit /b
