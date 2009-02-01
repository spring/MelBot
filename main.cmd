@echo off
pushd %~pd0
:start
"%~dp0bin\lua5.1.exe" "%~dp0main.lua" || goto ende
echo restarting...
goto start
:ende
popd
