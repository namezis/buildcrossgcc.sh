#!/bin/bash

# Based on script by: tautologico
# Source: https://gist.github.com/tautologico/3db84cf76fb85e9e3da8024251530d67

# This script expects the following archives with extension *.tar.xz

PKG_BINUTILS_NAME="binutils-2.32"
PKG_KERNEL_NAME="linux-4.19.49-stm32mp-r2"
PKG_GCC_NAME="gcc-8.3.0"
PKG_GLIBC_NAME="glibc-2.27"

TOOLCHAIN_OUTPUT_DIR="/home/yourhome/toolchains/gcc-arm-8.3-arm-linux-gnueabihf"

# gnome-terminal is used to monitor the build via the following file.
# The following is status log file truncated at startup appended during build:
# $STATUSLOG_DIR

logmessage() {
    printf "$*" >> $STATUSLOG_DIR
    printf "$*" >&2
}

bail() {
    logmessage "Error: $*"
    exit 1
}

print_usage() {
    cat << EOF

Print usage here

usage>
    script.sh <command>

EOF
}

############################################
#
# Prepare status log
#
STATUSLOG_DIR=`pwd`/status.log
echo "" > $STATUSLOG_DIR

# Uncomment this if you want to see progress
#gnome-terminal --window -- bash -i -c "tail -f $STATUSLOG_DIR"

#
############################################

logmessage "\nStarting build for GCC\n"

PROCS=$(grep 'processor' /proc/cpuinfo | wc | awk '{print $1}')
logmessage "\nSetting number of make processes to "$PROCS".\n\n"

if [ -d ./buildlog ]; then
    rm -rf ./buildlog
fi

# Create build log directory
mkdir buildlog
BUILDLOG_DIR=`pwd`/buildlog"/"

if [ ! -d $BUILDLOG_DIR ]; then
    bail "Unable to create build log directory."
fi

logmessage "Build log stored in "$BUILDLOG_DIR"\n\n"

###################################################################################################################################
###################################################################################################################################
#
# Download binutils, gcc, the linux kernel, glibc

# define the prefix
export PREFIX=$TOOLCHAIN_OUTPUT_DIR

# change PATH to include the target directory
export PATH=$PREFIX/bin:$PATH

###################################################################################################################################
#
# Build binutils
#

logmessage "### Extracting: "$PKG_BINUTILS_NAME"\n"

if [ -d $PKG_BINUTILS_NAME ]; then
    bail $PKG_BINUTILS_NAME" directory already exists."
fi

tar -xf $PKG_BINUTILS_NAME.tar.xz
[[ "$?" != "0" ]] && bail "Archive extraction failed."

if [ ! -d $PKG_BINUTILS_NAME ]; then
    bail "Cannot find "$PKG_BINUTILS_NAME" directory."
fi

logmessage "### Starting build for: "$PKG_BINUTILS_NAME"\n"

pushd ./$PKG_BINUTILS_NAME

logmessage "### Configuring\n"

./configure --prefix=$PREFIX --target=arm-linux-gnueabihf --with-arch=armv7a --with-fpu=vfp --with-float=hard \
            --disable-multilib 2>&1 | tee $BUILDLOG_DIR$PKG_BINUTILS_NAME-configure.log
[[ "$?" != "0" ]] && bail "Configuration failed."

logmessage "### Making\n"

make -j$PROCS 2>&1 | tee $BUILDLOG_DIR$PKG_BINUTILS_NAME-build.log
[[ "$?" != "0" ]] && bail "Make failed."

logmessage "### Installing\n"

make install 2>&1 | tee $BUILDLOG_DIR$PKG_BINUTILS_NAME-install.log
[[ "$?" != "0" ]] && bail "Make install failed."

popd

logmessage "### End "$PKG_BINUTILS_NAME" build.\n\n"

###################################################################################################################################
#
# Install the Linux kernel headers
#

logmessage "### Extracting: "$PKG_KERNEL_NAME"\n"

tar -xf $PKG_KERNEL_NAME.tar.xz
[[ "$?" != "0" ]] && bail "Archive extraction failed."

if [ ! -d $PKG_KERNEL_NAME ]; then
    bail "Cannot find "$PKG_KERNEL_NAME" directory."
fi

logmessage "### Starting installing kernel headers\n"

pushd ./$PKG_KERNEL_NAME

make ARCH=arm INSTALL_HDR_PATH=$PREFIX/arm-linux-gnueabihf headers_install 2>&1 | tee $BUILDLOG_DIR$PKG_KERNEL_NAME-headers_install.log
[[ "$?" != "0" ]] && bail "Make header installation failed."

popd

logmessage "### End "$PKG_KERNEL_NAME" headers installation.\n\n"

###################################################################################################################################
#
# Build gcc (first phase)
#

logmessage "### Extracting: "$PKG_GCC_NAME"\n"

tar -xf $PKG_GCC_NAME.tar.xz
[[ "$?" != "0" ]] && bail "Archive extraction failed."

if [ ! -d $PKG_GCC_NAME ]; then
    bail "Cannot find "$PKG_GCC_NAME" directory."
fi

logmessage "### Starting build (first phase) for: "$PKG_GCC_NAME"\n"

pushd ./$PKG_GCC_NAME

logmessage "### Downloading prerequisites for gcc build\n"
./contrib/download_prerequisites 2>&1 | tee $BUILDLOG_DIR$PKG_GCC_NAME-download_prerequisites.log
[[ "$?" != "0" ]] && bail "Downloading prerequisites failed."

mkdir build
pushd build

logmessage "### Configuring\n"

../configure --prefix=$PREFIX --target=arm-linux-gnueabihf --enable-languages=c,c++ --with-arch=armv7-a --with-fpu=vfp --with-float=hard \
             --disable-multilib 2>&1 | tee $BUILDLOG_DIR$PKG_GCC_NAME-configure.log
[[ "$?" != "0" ]] && bail "Configuration failed."

logmessage "### Making\n"

make -j$PROCS all-gcc 2>&1 | tee $BUILDLOG_DIR$PKG_GCC_NAME-all-gcc.log
[[ "$?" != "0" ]] && bail "Making all-gcc failed."

logmessage "### Installing\n"

make install-gcc 2>&1 | tee $BUILDLOG_DIR$PKG_GCC_NAME-install-gcc.log
[[ "$?" != "0" ]] && bail "Installing gcc failed."

popd
popd

logmessage "### End "$PKG_GCC_NAME" build (first phase).\n\n"

###################################################################################################################################
#
# Build glibc (first phase)
#

logmessage "### Extracting: "$PKG_GLIBC_NAME"\n"

tar -xf $PKG_GLIBC_NAME.tar.xz
[[ "$?" != "0" ]] && bail "Archive extraction failed."

if [ ! -d $PKG_GLIBC_NAME ]; then
    bail "Cannot find "$PKG_GLIBC_NAME" directory."
fi

logmessage "### Starting build (first phase) for: "$PKG_GLIBC_NAME"\n"

pushd ./$PKG_GLIBC_NAME

mkdir build
pushd build

logmessage "### Configuring\n"

../configure --prefix=$PREFIX/arm-linux-gnueabihf --build=$MACHTYPE --host=arm-linux-gnueabihf --target=arm-linux-gnueabihf \
             --with-arch=armv7a --with-fpu=vfp --with-float=hard --with-headers=$PREFIX/arm-linux-gnueabihf/include --disable-multilib \
               libc_cv_forced_unwind=yes 2>&1 | tee $BUILDLOG_DIR$PKG_GLIBC_NAME-configure.log
[[ "$?" != "0" ]] && bail "Configuration failed."

logmessage "### Making bootstrap\n"

make install-bootstrap-headers=yes install-headers 2>&1 | tee $BUILDLOG_DIR$PKG_GLIBC_NAME-install-headers.log
[[ "$?" != "0" ]] && bail "Install bootstrap headers failed."

make -j$PROCS csu/subdir_lib 2>&1 | tee $BUILDLOG_DIR$PKG_GLIBC_NAME-subdir_lib.log
[[ "$?" != "0" ]] && bail "Make subdir_lib failed."

logmessage "### Installing bootstrap\n"

install csu/crt1.o csu/crti.o csu/crtn.o $PREFIX/arm-linux-gnueabihf/lib 2>&1 | tee $BUILDLOG_DIR$PKG_GLIBC_NAME-install-o.log
[[ "$?" != "0" ]] && bail "Installing *.o failed."

arm-linux-gnueabihf-gcc -nostdlib -nostartfiles -shared -x c /dev/null -o $PREFIX/arm-linux-gnueabihf/lib/libc.so \
                        2>&1 | tee $BUILDLOG_DIR$PKG_GLIBC_NAME-build-libc.log
[[ "$?" != "0" ]] && bail "Compiling libc failed."

touch $PREFIX/arm-linux-gnueabihf/include/gnu/stubs.h
[[ "$?" != "0" ]] && bail "Unable to touch stabs header."

popd
popd

logmessage "### End "$PKG_GLIBC_NAME" build (first phase).\n\n"

###################################################################################################################################
#
# Build gcc (second phase, libgcc)
#

if [ ! -d $PKG_GCC_NAME/build ]; then
    bail "Cannot find "$PKG_GCC_NAME" build directory."
fi

logmessage "### Starting build (second phase, libgcc) for: "$PKG_GCC_NAME"\n"

pushd ./$PKG_GCC_NAME
pushd build

logmessage "### Making\n"

make -j$PROCS all-target-libgcc 2>&1 | tee $BUILDLOG_DIR$PKG_GCC_NAME-all-target-libgcc.log
[[ "$?" != "0" ]] && bail "Making failed."

logmessage "### Installing\n"

make install-target-libgcc 2>&1 | tee $BUILDLOG_DIR$PKG_GCC_NAME-install-target-libgcc.log
[[ "$?" != "0" ]] && bail "Installing failed."

popd
popd

logmessage "### End "$PKG_GCC_NAME" build (second phase, libgcc).\n\n"

###################################################################################################################################
#
# Build glibc (second phase)
#

if [ ! -d $PKG_GLIBC_NAME/build ]; then
    bail "Cannot find "$PKG_GLIBC_NAME" build directory."
fi

logmessage "### Starting build (second phase) for: "$PKG_GLIBC_NAME"\n"

pushd ./$PKG_GLIBC_NAME
pushd build

logmessage "### Making\n"

make -j$PROCS 2>&1 | tee $BUILDLOG_DIR$PKG_GLIBC_NAME-build.log
[[ "$?" != "0" ]] && bail "Making glibc failed."

logmessage "### Installing\n"

make install 2>&1 | tee $BUILDLOG_DIR$PKG_GLIBC_NAME-install.log
[[ "$?" != "0" ]] && bail "Installing glibc failed."

popd
popd

logmessage "### End "$PKG_GLIBC_NAME" build (second phase).\n\n"

###################################################################################################################################
#
# Build libstdc++
#

if [ ! -d $PKG_GCC_NAME/build ]; then
    bail "Cannot find "$PKG_GCC_NAME" build directory."
fi

logmessage "### Starting build (libstdc++) for: "$PKG_GCC_NAME"\n"

pushd ./$PKG_GCC_NAME
pushd build

logmessage "### Making\n"

make -j$PROCS 2>&1 | tee $BUILDLOG_DIR$PKG_GCC_NAME-libstdc++.log
[[ "$?" != "0" ]] && bail "Making libstdc++ failed."

logmessage "### Installing\n"

make install 2>&1 | tee $BUILDLOG_DIR$PKG_GCC_NAME-install.log
[[ "$?" != "0" ]] && bail "Installing libstdc++ failed."

popd
popd

logmessage "### End "$PKG_GCC_NAME" build (libstdc++).\n\n"

###################################################################################################################################

logmessage "Finished.\n\n"
