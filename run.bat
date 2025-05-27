echo off

cls
odin version

set OUT_DIR=build\debug\win64

echo run test
odin strip-semicolon crawler 
odin test crawler

echo create debug build directory
if exist %OUT_DIR% rmdir /s /q %OUT_DIR%
mkdir %OUT_DIR%

echo create debug build
odin build crawler -out:%OUT_DIR%\debug_version.exe -strict-style -vet -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

xcopy /y /e /i assets %OUT_DIR%\assets > nul
IF %ERRORLEVEL% NEQ 0 exit /b 1

echo Debug build created in %OUT_DIR%

echo Copy SDL3 DLLs to output directory
xcopy /y D:\DevTools\Odin\vendor\sdl3\*.dll %OUT_DIR% > nul
IF %ERRORLEVEL% NEQ 0 exit /b 1
xcopy /y D:\DevTools\Odin\vendor\sdl3\ttf\*.dll %OUT_DIR% > nul
IF %ERRORLEVEL% NEQ 0 exit /b 1

%OUT_DIR%\debug_version.exe 
