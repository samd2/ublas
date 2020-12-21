#!/bin/bash

set -ex
export TRAVIS_BUILD_DIR=$(pwd)
export TRAVIS_BRANCH=$DRONE_BRANCH
export TRAVIS_OS_NAME=${DRONE_JOB_OS_NAME:-linux}
export VCS_COMMIT_ID=$DRONE_COMMIT
export GIT_COMMIT=$DRONE_COMMIT
export DRONE_CURRENT_BUILD_DIR=$(pwd)
export PATH=~/.local/bin:/usr/local/bin:$PATH

echo '==================================> BEFORE_INSTALL'

. .drone/before-install.sh

echo '==================================> INSTALL'

cd ..
git clone -b master --depth 1 https://github.com/boostorg/boost.git boost-root
cd boost-root
git submodule update --init --jobs 8 tools/build
git submodule update --init --jobs 8 libs/config
git submodule update --init --jobs 8 tools/boostdep
mkdir -p libs/numeric/
cp -rp $TRAVIS_BUILD_DIR/. libs/numeric/ublas
python tools/boostdep/depinst/depinst.py -I benchmarks numeric/ublas
./bootstrap.sh
./b2 -j 8 headers
export BOOST_ROOT="`pwd`"

echo '==================================> BEFORE_SCRIPT'

. $DRONE_CURRENT_BUILD_DIR/.drone/before-script.sh

echo '==================================> SCRIPT'

echo "using $TOOLSET : : $COMPILER ;" >> ~/user-config.jam;
echo "using clblas : : <include>${CLBLAS_PREFIX}/include <search>${CLBLAS_PREFIX}/lib ;" >> ~/user-config.jam;
cp $TRAVIS_BUILD_DIR/opencl.jam ~/
cp $TRAVIS_BUILD_DIR/clblas.jam ~/
cd libs/numeric/ublas
$BOOST_ROOT/b2 -j 8 test toolset=$TOOLSET cxxstd=$CXXSTD

echo '==================================> AFTER_SUCCESS'

. $DRONE_CURRENT_BUILD_DIR/.drone/after-success.sh
