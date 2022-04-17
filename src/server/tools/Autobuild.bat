@echo off &setlocal
:config
cd %~dp0
cls
title Autobuild: config
set "sourcefile=DockerfileTemplate"
set "tempfile=Dockerfile"
set "replacmentString=GETS_REPLACED_AUTOMATICALLY_FROM_BATCH_FILE"

set /p version=Version: 
set /p tag=Tag: 
goto :buildConfig

:build
cd %~dp0
cls
:buildConfig
:: export response and eventlist
set start=%time%

@echo .
title Autobuild: export response eventlist
start /W /B cmd /c python ExportSharedResponseEventList.py
@echo Export done!
cd ..
@echo .

@echo create temporary dockerfile

:: replace version in dockerfile
(for /f "delims=" %%i in (%sourcefile%) do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    set "line=!line:%replacmentString%=%version%!"
    echo(!line!
    endlocal
))>"%tempfile%"
@echo temporary dockerfile created
:: build the docker image
@echo .
@echo .

title Autobuil: building dockerimage version: %version% tag: %tag% ...
start /W /B cmd /c docker buildx build --tag carlkuhligk/securitymotiontracker:%tag% --platform=linux/386,linux/amd64,linux/arm/v5,linux/arm/v7,linux/arm64/v8 --push .
@echo .

title Autobuild: building process done!
@echo remove temporary dockerfile
del %tempfile%

set end=%time%
set options="tokens=1-4 delims=:.,"
for /f %options% %%a in ("%start%") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100&set /a start_ms=100%%d %% 100
for /f %options% %%a in ("%end%") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100&set /a end_ms=100%%d %% 100

set /a hours=%end_h%-%start_h%
set /a mins=%end_m%-%start_m%
set /a secs=%end_s%-%start_s%
set /a ms=%end_ms%-%start_ms%
if %ms% lss 0 set /a secs = %secs% - 1 & set /a ms = 100%ms%
if %secs% lss 0 set /a mins = %mins% - 1 & set /a secs = 60%secs%
if %mins% lss 0 set /a hours = %hours% - 1 & set /a mins = 60%mins%
if %hours% lss 0 set /a hours = 24%hours%
if 1%ms% lss 100 set ms=0%ms%

:: build accomplished
set /a totalsecs = %hours%*3600 + %mins%*60 + %secs%
@echo .
@echo .
@echo completed: %date% %time%
@echo process took %hours%:%mins%:%secs%.%ms% (%totalsecs%.%ms%s total)
@echo image version: %version% tag: %tag%
@echo .

:section
@echo .
@echo .
@echo PRESS 1 BUILD AGAIN
@echo PRESS 2 CHANGE VERSION/TAG
@echo PRESS 3 EXIT
set /p selection=Selection: 
if %selection% == 1 goto :build
if %selection% == 2 goto :config
if %selection% == 3 exit
goto :section
