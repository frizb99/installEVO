pushd %~dp0
@echo off

setlocal enabledelayedexpansion
rem set folderName=
rem set storeType=
set errorlog=errors.txt
set successlog=success.log
set timeoutlog=timeout.log
rem set pseUser=ridenow\psexecUser
rem set psePass=bxCpPZyPkgxU9aU8
rem set roboOptions=/E /R:2 /W:10 /NDL /XO /NP /log+:C:\Support\EVO-^^!storeType^^!.txt


set /p description="Enter description for log file (optional): "
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

rem cls
echo   Please select uninstall type:
echo.
rem echo   M    Metric ^& Indian EVO
rem echo   H    Harley EVO
echo   TM   Test/sandbox EVO for Metric stores
echo   TH   Test/sandbox EVO for Harley stores
rem echo   MTM  Metric and Test Metric EVO
rem echo   HTH  Harley and Test Harley EVO
echo   A    All of the above
echo.
set /p installType="Install type? (M,H,TM,TH,MTM,HTH,A)"
rem if /i "%installType%" EQU "M" (set storeType=Metric & set folderName=LightspeedEVO)
rem if /i "%installType%" EQU "H" (set storeType=Harley & set folderName=LightspeedEVO-HD)
if /i "%installType%" EQU "TM" (set storeType=MeTest & set folderName=LightspeedEVO-TestMetric)
if /i "%installType%" EQU "TH" (set storeType=HDTest & set folderName=LightspeedEVO-TestHD)
rem if /i "%installType%" EQU "MTM" (set storeType=MTM)
rem if /i "%installType%" EQU "HTH" (set storeType=HTH)
if /i "%installType%" EQU "A" (set storeType=All)

if not defined storeType goto :eof
call :printStoreIP
set /p ipOctet="Enter a unique IP address octet for %serverName:~0,4% (optional) "

FOR /F %%i IN (%hostnameFile%) DO (
call pingHost.cmd %%i %ipOctet%
if !errorlevel! EQU 0 (
  echo *** Starting process on %%i ****************************
  if %storeType% equ All (
    call :main %%i Metric LightspeedEVO
    call :main %%i Harley LightspeedEVO-HD
    call :main %%i MeTest LightspeedEVO-TestMetric
    call :main %%i HDTest LightspeedEVO-TestHD
  ) else if %storeType% equ MTM (
    call :main %%i Metric LightspeedEVO
    call :main %%i MeTest LightspeedEVO-TestMetric
  ) else if %storeType% equ HTH (
    call :main %%i Harley LightspeedEVO-HD
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
rem icacls LightspeedEVO-NV07 /grant RIDENOW\Domain Users:(OI)(CI)(M) /t

  if exist "\\%pc%\c$\Program Files (x86)" (
    set pgmFiles=Program Files ^(x86^)\%folderName%
    set type=64-bit
  ) else (
    rem path not found, so lets try 32 bit...
    set pgmFiles=Program Files\%folderName%
    set type=32-bit
  )

rem if not exist "\\%pc%\C$\%pgmFiles%" md "\\%pc%\C$\%pgmFiles%"
rem if not exist "\\%pc%\c$\Support" mkdir "\\%pc%\C$\Support"
:: Copy lswhite icon to C:\support if it doesnt already exist.
rem if not exist \\%pc%\C$\Support\lswhite.ico psexec \\%pc% -u %pseUser% -p %psePass% -e -n 10 -nobanner cmd /c  copy "%source%\..\Support Files\lswhite.ico" "C:\Support"
rem psexec \\%pc% -s -n 10 -nobanner icacls "C:\!pgmFiles!" /grant "RIDENOW\Domain Users":^(OI^)^(CI^)F 
rem psexec \\%pc% -u %pseUser% -p %psePass% -e -n 10 -nobanner robocopy "%source%" "C:\!pgmFiles!" * %roboOptions% 
echo on
  set filename=Lightspeed EVO%folderName:~13%.lnk
del \\%pc%\c$\users\Public\Desktop\!filename!
set roboresult=!errorlevel!
if !roboresult! LEQ 7 (call :writeSuccess) else call :writeError
exit /b

:writeSuccess
set description=!roboresult!
echo success !roboresult!
echo !type! %storeType% icon deleted %pc% at !time! with error %description% --test-->> %successlog%
exit /b

:writeError
set description=!roboresult!
echo error !roboresult!
echo %pc%-!date!-!time!-"%type%"-%description% --test-->> %errorlog%
exit /b

