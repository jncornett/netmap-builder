#!/usr/bin/env bash

# constants
{
  SRCPATH=/src/LINUX
  OUTPATH=/out
}

# arguments
{
  VERSION="${1?no version specified}"
}

# globals
{
  KERNEL_DIR="/usr/src/kernels/${VERSION}.x86_64"
}

set -e

# install the appropriate kernel version
dnf install -y "kernel-devel-${VERSION}.x86_64"

cd $SRCPATH
./configure --kernel-dir=$KERNEL_DIR --no-drivers
make -j$(nproc)
mkdir -p $OUTPATH
cp netmap.ko $OUTPATH
