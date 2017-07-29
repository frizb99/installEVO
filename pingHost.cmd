@echo off

if "%1" == "" (
  echo You must provide the hostname of the system to check.
  echo. 
  echo pingHost hostname [partial_IP_addr]
  echo.
  echo Returns the following errorlevels:
  echo 0  Success; host found
  echo 1  Destination host unreachable.
  echo 2  Hostname not found; DNS record not found.
  echo 3  Host found, but IP does not match [partial_IP_addr]
  pause
  goto :EOF
)
if "%log%" == "" set log=nul
rem set log=con

ping -n 1 %1 > %temp%\search
if /i _%log% EQU _con type %temp%\search
find "bytes=" %temp%\search > nul
if /i _%log% EQU _con echo Search for bytes returns %errorlevel%

if %errorlevel% EQU 0 (
  if /i _%log% EQU _con Echo %1 is alive!
  echo %1;Up >> %log%
  set errorlvl=0
  if "%2" NEQ "" call :checkLocation %1 %2
) else (
  find "unreachable" %temp%\search > nul
  if /i _%log% EQU _con echo Search for unreachable returns %errorlevel%
  if %errorlevel% EQU 0 (
    Echo Destination host unreachable.
    echo %1;unreachable >> %log%
    set errorlvl=1
    ) else (
    find "could not find host" %temp%\search > nul
    if /i _%log% EQU _con echo Search for could not find host returns %errorlevel%
    if %errorlevel% EQU 0 (
      Echo Ping could not resolve host %1.
      echo %1;Cannot resolve >> %log%
      set errorlvl=2
      ) else (
      echo %1;Offline >> %log%
        set errorlvl=3
      )
    )
rem    timeout 5
  )

del %temp%\search
if /i _%log% EQU _con echo final %errorlvl%

exit /b %errorlvl%




:checkLocation
  rem Check if hostname is within specified network range.
  find "%2" %temp%\search > nul
  if /i _%log% EQU _con echo Network search results returned errorlevel %errorlevel%
  if %errorlevel% EQU 1 set errorlvl=4
EXIT /B

