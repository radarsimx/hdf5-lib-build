#!/bin/bash

workpath=$(pwd)

echo "## Clean old build files ##"
rm -rf ./build
rm -rf ./hdf5lib

echo "## Building libradarsimcpp.so with ${ARCH^^} ##"
mkdir ./build
cd ./build

cmake -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS:BOOL=OFF -DBUILD_TESTING:BOOL=OFF -DHDF5_BUILD_TOOLS:BOOL=OFF -DHDF5_BUILD_EXAMPLES:BOOL=OFF -DHDF5_BUILD_UTILS:BOOL=OFF -DHDF5_BUILD_CPP_LIB:BOOL=ON ../hdf5

cmake --build .

cd ..

mkdir ./hdf5lib
mkdir ./hdf5lib/include
mkdir ./hdf5lib/lib

echo "## Copying lib files to ./radarsimpy ##"
cp ./hdf5/c++/src/*.h ./hdf5lib/include/
cp ./hdf5/src/*.h ./hdf5lib/include/
cp ./hdf5/src/H5FDsubfiling/*.h ./hdf5lib/include/
cp ./build/src/*.h ./hdf5lib/include/

cp ./build/bin/Release/*.a ./hdf5lib/lib/