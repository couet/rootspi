@echo off

echo Execution started: %date% %time%

rem ---Compiler------------------------------------------------------
rem if "%COMPILER%" == "" (
if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars32.bat" (
  call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars32.bat" x86
) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars32.bat" (
  call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars32.bat" x86
)
rem ) else (
rem   if %COMPILER% == vc9   call "%VS90COMNTOOLS%vsvars32.bat"
rem   if %COMPILER% == vc10  call "%VS100COMNTOOLS%vsvars32.bat"
rem   if %COMPILER% == vc11  call "%VS110COMNTOOLS%vsvars32.bat"
rem   if %COMPILER% == vc12  call "%VS120COMNTOOLS%vsvars32.bat"
rem   if %COMPILER% == vc13  call "%VS130COMNTOOLS%vsvars32.bat"
rem   if %COMPILER% == vc15  call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\Common7\Tools\VsDevCmd.bat"
rem   if %COMPILER% == native call "C:\Program Files (x86)\Microsoft Visual Studio\2017\Community\VC\Auxiliary\Build\vcvars32.bat" x86
rem )

rem ---Run the CTest script depending on the compiler------------------------------------------

set THIS=%~d0%~p0
set NCORES=%NUMBER_OF_PROCESSORS%
set BUILD_VERSION=%VERSION%
if "%NCORES%" == "" set NCORES=4
if "%NCORES%" == "16" set NCORES=12
if "%NCORES%" == "32" set NCORES=24
set ACTION=%1
set RUN_TESTS=no

if "%BUILD_VERSION%" neq "" (
    if "%BUILD_VERSION%" == "master" (
        set RUN_TESTS=yes
    ) else (
        if "%BUILD_VERSION:~1,1%" == "6" if "%BUILD_VERSION:~3,2%" geq "23" set RUN_TESTS=yes
        if "%BUILD_VERSION:~1,1%" geq "7" set RUN_TESTS=yes
    )
)

if "%ACTION%" neq "test" (

    echo Dumping the full environment ---------------------------------------------------------
    set | find /V "ghprbPullLongDescription" | find /V "ghprbPullDescription" | find /V "ghprbPullTitle" | find /V "ghprbCommentBody"
    echo --------------------------------------------------------------------------------------

    ctest -j%NCORES% -VV -S %THIS%/root-build.cmake
    set error_level=%ERRORLEVEL%

    rem do not run the tests if continuous build fails
    if %error_level% neq 0 (
        exit /b %error_level%
    )

    rem do not run tests if coverity run or package build.
    if "%BUILDOPTS%" == "coverity" (
        exit /b %error_level%
    )
    if "%MODE%" == "package" (
        exit /b %error_level%
    )
)

if "%ACTION%" neq "build" (
    if "%RUN_TESTS%" == "yes" (
        echo Dumping the full environment ---------------------------------------------------------
        set
        echo --------------------------------------------------------------------------------------

        ctest --no-compress-output -V -S %THIS%/root-test.cmake
        set error_level=%ERRORLEVEL%
    ) else (
        exit /b 0
    )
)

exit /b %error_level%

