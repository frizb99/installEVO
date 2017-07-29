@echo off
rem now we check for admin privilages and re-launch as admin if needed
:: BatchGotAdmin (Run as Admin code starts)
REM --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\icacls.exe" "%SYSTEMROOT%\system32\config\system"
REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
  echo Requesting administrative privileges...
  goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B
:gotAdmin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
CD /D "%~dp0"
:: BatchGotAdmin (Run as Admin code ends)
pushd %~dp0


setlocal enabledelayedexpansion
set folderName=
set storeType=

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

set roboOptions=/E /R:2 /W:10 /NDL /XO 

if %storeType% equ All (
  call :main Metric LightspeedEVO
  call :main Harley LightspeedEVO-HD
  call :main MeTest LightspeedEVO-TestMetric
  call :main HDTest LightspeedEVO-TestHD
) else call :main %storeType% %folderName%

exit /b

:main
set storeType=%1
set folderName=%2
  if exist "C:\Program Files (x86)" (
    set pgmFiles=Program Files ^(x86^)\%folderName%
    set type=64-bit
  ) else (
    rem path not found, so lets try 32 bit...
    set pgmFiles=Program Files\%folderName%
    set type=32-bit
  )
set source=.\%folderName%
md "C:\%pgmFiles%"
icacls "C:\%pgmFiles%" /grant Everyone:^(OI^)^(CI^)F 
robocopy "%source%" "C:\%pgmFiles%" * %roboOptions%
set roboresult=!errorlevel!
if !roboresult! LEQ 7 (
  rem the next line appends all characters from folderName after the 13th char (after "EVO")
  rem this is so we can create the shortcut name with a space in it.
  set filename=Lightspeed EVO%folderName:~13%.lnk
  call shortcutJS.bat -linkfile "C:\Users\Public\Desktop\!filename!" -target "C:\%pgmFiles%\Lightspeed.bat" -workingdirectory "C:\%pgmFiles%" -windowstyle 7 -iconlocation "C:\%pgmFiles%\ls.ico",0 -description "Lightspeed Dealer Management System"
  icacls "C:\%pgmFiles%" /grant Everyone:^(OI^)^(CI^)F /t /q
  if not exist C:\LSTemp mkdir C:\LSTemp && icacls C:\LSTemp /grant Everyone:^(OI^)^(CI^)F /t /q
)
call :writeError
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
if !roboresult! EQU 7 set description=missing files copied. + MISMATCHES + XTRA
if !roboresult! EQU 6 set description=MISMATCHES + XTRA
if !roboresult! EQU 5 set description=missing files copied. + MISMATCHES
if !roboresult! EQU 4 set description=MISMATCHES
if !roboresult! EQU 3 set description=extra files detected in destination. Missing files copied.
if !roboresult! EQU 2 set description=extra files detected in destination. No files copied.
if !roboresult! EQU 1 set description=no errors.
if !roboresult! EQU 0 set description=no changes (files identical)

echo !type! %storeType% file copy to %pc% at !time! completed with %description%
if %roboresult% GTR 7 (
  echo *** NOTE ***
  echo Errors have been found when trying to copy %folderName% to
  echo the computer. Please review text above, as there is no error log created.
  echo.
  pause
)

exit /b
