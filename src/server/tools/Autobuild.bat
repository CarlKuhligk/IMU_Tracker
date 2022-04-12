@echo off &setlocal
title Autobuild: config
set "sourcefile=DockerfileTemplate"
set "tempfile=Dockerfile"
set "replacmentString=GETS_REPLACED_AUTOMATICALLY_FROM_BATCH_FILE"
color 04
set /p version=Version: 
set /p tag=Tag: 
color 07
:: export response and eventlist
echo .
title Autobuild: export response eventlist
start /W /B cmd /c python ExportSharedResponseEventList.py
echo Export done!
cd ..
echo .
color 0D
echo create temporary dockerfile
color 07
:: replace version in dockerfile
(for /f "delims=" %%i in (%sourcefile%) do (
    set "line=%%i"
    setlocal enabledelayedexpansion
    set "line=!line:%replacmentString%=%version%!"
    echo(!line!
    endlocal
))>"%tempfile%"
echo temporary dockerfile created
:: build the docker image
echo .
echo .
color 07
title Autobuil: building dockerimage version: %version% tag: %tag% ...
start /W /B cmd /c docker buildx build --tag carlkuhligk/securitymotiontracker:%tag% --platform=linux/386,linux/amd64,linux/arm/v5,linux/arm/v7,linux/arm64/v8 --push .
echo .
color 01
echo build done!
echo image version: %version% tag: %tag%
color 0D
echo remove temporary dockerfile
del %tempfile%
echo .
echo .
title Autobuild: building process done!
echo DONE!
color 0A
echo .
echo .
pause
