@echo off
REM ==============================================================================
REM HDF5 Library Build Script for Windows
REM ==============================================================================
REM
REM This script builds HDF5 libraries for Windows x86_64 architecture.
REM It configures HDF5 with C++ support and static linking for use with
REM the RadarSimCpp project.
REM
REM Requirements:
REM   - CMake 3.18 or higher
REM   - Visual Studio 2019 or higher (with C++ tools)
REM   - HDF5 source code in ./hdf5 directory
REM
REM Output:
REM   - ./hdf5lib/include/  - Header files
REM   - ./hdf5lib/lib/      - Static library files (.lib)
REM
REM Usage:
REM   build.bat [options]
REM
REM Arguments:
REM   clean   - Force clean build (removes all build artifacts)
REM   debug   - Build in Debug mode (default is Release)
REM
REM Examples:
REM   build.bat              - Release build
REM   build.bat debug        - Debug build
REM   build.bat clean        - Clean Release build
REM   build.bat clean debug  - Clean Debug build
REM
REM ==============================================================================

REM Configuration - defaults
set BUILD_TYPE=Release
set BUILD_DIR=.\build
set OUTPUT_DIR=.\output
set HDF5_SOURCE_DIR=.\hdf5
set PLATFORM=win_x86_64
set FORCE_CLEAN=

REM Parse command line arguments
:parse_args
if "%1"=="" goto done_args
if /i "%1"=="clean" (
    set FORCE_CLEAN=1
    echo INFO: Force clean build requested
)
if /i "%1"=="debug" (
    set BUILD_TYPE=Debug
    echo INFO: Debug build requested
)
shift
goto parse_args
:done_args

echo INFO: Platform: %PLATFORM%
echo INFO: Build type: %BUILD_TYPE%

REM Check if CMake is available
cmake --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: CMake is not installed or not in PATH
    echo Please install CMake 3.18 or higher
    exit /b 1
)

REM Check if HDF5 source directory exists
if not exist "%HDF5_SOURCE_DIR%" (
    echo ERROR: HDF5 source directory not found: %HDF5_SOURCE_DIR%
    echo Please ensure HDF5 source code is available
    exit /b 1
)

REM Clean old build files
echo INFO: Cleaning old build files...
if exist "%BUILD_DIR%" (
    rmdir /q /s "%BUILD_DIR%" 2>nul
    if %errorlevel% neq 0 (
        echo WARNING: Failed to remove build directory, continuing...
    )
)

if exist "%OUTPUT_DIR%" (
    if defined FORCE_CLEAN (
        rmdir /q /s "%OUTPUT_DIR%" 2>nul
        if %errorlevel% neq 0 (
            echo WARNING: Failed to remove output directory, continuing...
        )
    )
)

REM Create build directory
echo INFO: Creating build directory...
mkdir "%BUILD_DIR%" 2>nul
if not exist "%BUILD_DIR%" (
    echo ERROR: Failed to create build directory
    exit /b 1
)

REM Change to build directory
pushd "%BUILD_DIR%"

REM Configure CMake
echo INFO: Configuring CMake...
cmake ^
    -DCMAKE_BUILD_TYPE:STRING=%BUILD_TYPE% ^
    -DBUILD_SHARED_LIBS:BOOL=OFF ^
    -DBUILD_TESTING:BOOL=OFF ^
    -DHDF5_BUILD_TOOLS:BOOL=OFF ^
    -DHDF5_BUILD_EXAMPLES:BOOL=OFF ^
    -DHDF5_BUILD_UTILS:BOOL=OFF ^
    -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF ^
    -DHDF5_ENABLE_Z_LIB_SUPPORT:BOOL=OFF ^
    -DHDF5_BUILD_CPP_LIB:BOOL=ON ^
    -DHDF5_BUILD_HL_LIB:BOOL=ON ^
    -DHDF5_BUILD_FORTRAN:BOOL=OFF ^
    -DHDF5_BUILD_JAVA:BOOL=OFF ^
    "../%HDF5_SOURCE_DIR%"

if %errorlevel% neq 0 (
    echo ERROR: CMake configuration failed
    popd
    exit /b 1
)

REM Build the project
echo INFO: Building HDF5 libraries...
cmake --build . --config %BUILD_TYPE% --parallel

if %errorlevel% neq 0 (
    echo ERROR: Build failed
    popd
    exit /b 1
)

REM Return to original directory
popd

REM Create output directory structure
echo INFO: Creating output directory structure...
mkdir "%OUTPUT_DIR%" 2>nul
mkdir "%OUTPUT_DIR%\include" 2>nul
mkdir "%OUTPUT_DIR%\include_%PLATFORM%" 2>nul
mkdir "%OUTPUT_DIR%\lib_%PLATFORM%" 2>nul

REM Copy header files
echo INFO: Copying header files...
xcopy /y /q "%HDF5_SOURCE_DIR%\c++\src\*.h" "%OUTPUT_DIR%\include\" 2>nul
if %errorlevel% neq 0 (
    echo WARNING: Some C++ header files may not have been copied
)

xcopy /y /q "%HDF5_SOURCE_DIR%\src\*.h" "%OUTPUT_DIR%\include\" 2>nul
if %errorlevel% neq 0 (
    echo WARNING: Some C header files may not have been copied
)

xcopy /y /q "%HDF5_SOURCE_DIR%\src\H5FDsubfiling\*.h" "%OUTPUT_DIR%\include\" 2>nul
if %errorlevel% neq 0 (
    echo WARNING: Some subfiling header files may not have been copied
)

xcopy /y /q "%BUILD_DIR%\src\*.h" "%OUTPUT_DIR%\include_%PLATFORM%\" 2>nul
if %errorlevel% neq 0 (
    echo WARNING: Some generated header files may not have been copied
)

REM Copy library files
echo INFO: Copying library files...
xcopy /y /q "%BUILD_DIR%\bin\%BUILD_TYPE%\*.lib" "%OUTPUT_DIR%\lib_%PLATFORM%\" 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Failed to copy library files
    exit /b 1
)

REM Verify output
echo INFO: Verifying build output...
set LIB_COUNT=0
for %%f in ("%OUTPUT_DIR%\lib_%PLATFORM%\*.lib") do (
    set /a LIB_COUNT+=1
)

if %LIB_COUNT% equ 0 (
    echo ERROR: No library files found in output directory
    exit /b 1
)

echo INFO: Build completed successfully!
echo INFO: Libraries: %LIB_COUNT% files in %OUTPUT_DIR%\lib_%PLATFORM%\
echo INFO: Headers: Available in %OUTPUT_DIR%\include\ and %OUTPUT_DIR%\include_%PLATFORM%\
echo INFO: Build artifacts: %BUILD_DIR%\

exit /b 0
