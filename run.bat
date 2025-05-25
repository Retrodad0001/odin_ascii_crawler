@echo off

cls
odin version

set OUT_DIR=build\debug\win64

rem run test
odin strip-semicolon crawler 
odin test crawler

if exist %OUT_DIR% rmdir /s /q %OUT_DIR%
mkdir %OUT_DIR%

odin build crawler -out:%OUT_DIR%\debug_version.exe -strict-style -vet -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

xcopy /y /e /i assets %OUT_DIR%\assets > nul
IF %ERRORLEVEL% NEQ 0 exit /b 1

echo Debug build created in %OUT_DIR%

%OUT_DIR%\debug_version.exe
