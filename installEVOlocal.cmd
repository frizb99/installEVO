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
set roboOptions=/E /R:2 /W:10 /NDL /XO 
cls
echo Run this command from the server in the same network as the computer you want
echo to install on. This script will robocopy the source to the Program Files
echo folder, update the permissions of the folder to Domain Users, and create a
echo shortcut on the Public Users desktop ^(C:\Users\Public\Desktop^)
echo New 7/28: Sets permissions for Domain Users instead of Everyone.
echo           Added option to install Test and Production.
echo           I've also made sure the icon stays white.
echo.
echo   Please select install type:
echo.
echo   M    Metric ^& Indian EVO
echo   H    Harley EVO
echo   TM   Test/sandbox EVO for Metric stores
echo   TH   Test/sandbox EVO for Harley stores
echo   MTM  Metric and Test Metric EVO
echo   HTH  Harley and Test Harley EVO
echo   A    All of the above
echo.
set /p installType="Install type? (M,H,TM,TH,MTM,HTH,A)"
if /i "%installType%" EQU "M" (set storeType=Metric & set folderName=LightspeedEVO)
if /i "%installType%" EQU "H" (set storeType=Harley & set folderName=LightspeedEVO-HD)
if /i "%installType%" EQU "TM" (set storeType=MeTest & set folderName=LightspeedEVO-TestMetric)
if /i "%installType%" EQU "TH" (set storeType=HDTest & set folderName=LightspeedEVO-TestHD)
if /i "%installType%" EQU "MTM" (set storeType=MTM)
if /i "%installType%" EQU "HTH" (set storeType=HTH)
if /i "%installType%" EQU "A" (set storeType=All)
if not defined storeType goto :eof

  if %storeType% equ All (
    call :main Metric LightspeedEVO
    call :main Harley LightspeedEVO-HD
    call :main MeTest LightspeedEVO-TestMetric
    call :main HDTest LightspeedEVO-TestHD
  ) else if %storeType% equ MTM (
    call :main Metric LightspeedEVO
    call :main MeTest LightspeedEVO-TestMetric
  ) else if %storeType% equ HTH (
    call :main Harley LightspeedEVO-HD
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
set iconFile=C:\!pgmFiles!\ls.ico
if %storeType:~-4% EQU Test set iconFile=C:\Support\lswhite.ico

if not exist "C:\%pgmFiles%" md "C:\%pgmFiles%"
if not exist "C:\Support" md "C:\Support"
@pause
:: Copy lswhite icon to C:\support if it doesnt already exist.
if not exist "C:\Support\lswhite.ico" copy "%source%\..\Support Files\lswhite.ico" "C:\Support"
icacls "C:\%pgmFiles%" /grant "RIDENOW\Domain Users":^(OI^)^(CI^)F 
robocopy "%source%" "C:\%pgmFiles%" * %roboOptions%
set roboresult=!errorlevel!
if !roboresult! LEQ 7 (
  rem the next line appends all characters from folderName after the 13th char (after "EVO")
  rem this is so we can create the shortcut name with a space in it.
  set filename=Lightspeed EVO%folderName:~13%.lnk
  call shortcutJS.bat -linkfile "C:\Users\Public\Desktop\!filename!" -target "C:\%pgmFiles%\Lightspeed.bat" -workingdirectory "C:\%pgmFiles%" -windowstyle 7 -iconlocation "%iconFile%",0 -description "Lightspeed Dealer Management System"
  icacls "C:\%pgmFiles%" /grant "RIDENOW\Domain Users":^(OI^)^(CI^)F /t /q
  if not exist C:\LSTemp mkdir C:\LSTemp & icacls C:\LSTemp /grant Everyone:^(OI^)^(CI^)F /t /q
)
call :displayResults
exit /b

:displayResults
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
