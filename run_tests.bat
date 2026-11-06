@echo off
echo ========================================================
echo Running DayBook Automated Full System Verification
echo ========================================================

echo.
echo [1/3] Running Flutter Static Analysis and Tests...
cd "%~dp0"
call flutter analyze --no-fatal-infos
if %ERRORLEVEL% NEQ 0 (
    echo Flutter analysis failed!
    exit /b %ERRORLEVEL%
)

call flutter test
if %ERRORLEVEL% NEQ 0 (
    echo Flutter tests failed!
    exit /b %ERRORLEVEL%
)

echo.
echo [2/3] Running NestJS Backend Security Tests...
cd "%~dp0backend"
call node test/run-tests.js
if %ERRORLEVEL% NEQ 0 (
    echo Backend tests failed!
    exit /b %ERRORLEVEL%
)

echo.
echo [3/3] Running Website Verification Tests (40/40)...
cd "%~dp0"
call node website/verify_website.js
if %ERRORLEVEL% NEQ 0 (
    echo Website verification failed!
    exit /b %ERRORLEVEL%
)

echo.
echo ========================================================
echo ALL 225 FULL-SYSTEM TESTS PASSED SUCCESSFULLY!
echo ========================================================
