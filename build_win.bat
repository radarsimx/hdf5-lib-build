ECHO clean old build files
RMDIR /Q/S .\build

@REM go to the build folder
MD ".\build"
CD ".\build"

cmake -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF -DBUILD_TESTING:BOOL=OFF -DHDF5_BUILD_TOOLS:BOOL=OFF -DHDF5_BUILD_EXAMPLES:BOOL=OFF -DHDF5_BUILD_CPP_LIB:BOOL=ON ../hdf5

cmake --build . --config Release