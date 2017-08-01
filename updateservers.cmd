setlocal enabledelayedexpansion

set serverList1=willisserver rnssserver nv01server
set serverList2=az12server az09server az13server
set serverList3=az07server az08server fl01server
set serverList4=az11server az03server az17server
set serverList5=nv06server fl08server
set startTime=%time%

if "%1" NEQ "" goto main

for /l %%i in (1,1,5) do (
  start "List%%i" %0 List%%i
)
rem start "group 1" FOR %%i IN (%serverList1%) DO robocopy \\rnssitstorage\software\evo "\\%%i\support files\evo" * %roboOptions%

@echo ***** done here
rem @pause
exit /b

:main

set roboOptions=/R:2 /W:1 /NDL /NP /mir /njh
set list=^!server%1^!
rem
rem set list

cls
@echo off
echo Starting server%1: %list%
FOR %%i IN (%list%) DO (
echo.
echo.
echo Starting RoboCopy on %%i...
  robocopy \\rnssitstorage\software\evo "\\%%i\support files\evo" * %roboOptions%
)

echo Completed server%1: %list%
@echo Start time was: %startTime%
@echo Finish time is: %time%
@pause
exit