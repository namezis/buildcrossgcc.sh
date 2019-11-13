This is very simple script that builds complete GCC toolschain.

It is based on script by: tautologico
which can be found here: https://gist.github.com/tautologico/3db84cf76fb85e9e3da8024251530d67

This script expects the following archives with extension *.tar.xz

binutils-2.32.tar.xz<br>
gcc-8.3.0.tar.xz<br>
glibc-2.27.tar.xz<br>
linux-4.19.49-stm32mp-r2.tar.xz<br>

These will be extracted in the same directory.

Diffrent versions can be setup using these variables:

PKG_BINUTILS_NAME="binutils-2.32"<br>
PKG_KERNEL_NAME="linux-4.19.49-stm32mp-r2"<br>
PKG_GCC_NAME="gcc-8.3.0"<br>
PKG_GLIBC_NAME="glibc-2.27"<br>

The output of your toolchain can be set by:

TOOLCHAIN_OUTPUT_DIR="/home/yourhome/toolchains/gcc-arm-8.3-arm-linux-gnueabihf"
