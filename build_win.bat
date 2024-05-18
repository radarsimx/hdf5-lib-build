ECHO clean old build files
RMDIR /Q/S .\build
RMDIR /Q/S .\hdf5lib

@REM go to the build folder
MD ".\build"
CD ".\build"

cmake -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF -DBUILD_TESTING:BOOL=OFF -DHDF5_BUILD_TOOLS:BOOL=OFF -DHDF5_BUILD_EXAMPLES:BOOL=OFF -DHDF5_BUILD_UTILS:BOOL=OFF -DHDF5_ENABLE_SZIP_SUPPORT:BOOL=OFF -DHDF5_BUILD_CPP_LIB:BOOL=ON ../hdf5

cmake --build . --config Release

CD ..

MD ".\hdf5lib"
MD ".\hdf5lib\include"
MD ".\hdf5lib\lib"

XCOPY ".\hdf5\c++\src\*.h" ".\hdf5lib\include\"
XCOPY ".\hdf5\src\*.h" ".\hdf5lib\include\"
XCOPY ".\hdf5\src\H5FDsubfiling\*.h" ".\hdf5lib\include\"
XCOPY ".\build\src\*.h" ".\hdf5lib\include\"

XCOPY ".\build\bin\Release\*.lib" ".\hdf5lib\lib\"
