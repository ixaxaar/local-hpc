#!/bin/bash

set -e
set -o pipefail

# Variables
LUSTRE_REPO="git://git.whamcloud.com/fs/lustre-release.git"
LUSTRE_BRANCH="2.15.63"

KERNEL_VERSION="6.9.4"
KERNEL_URL="https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-$KERNEL_VERSION.tar.xz"

ZFS_REPO="https://github.com/zfsonlinux/zfs.git"
ZFS_BRANCH="zfs-2.2.4"
# CONFIG_FILE="./zen.config"

BUILD_DIR="$HOME/lustre_build"
KERNEL_DIR="$BUILD_DIR/linux-$KERNEL_VERSION"
LUSTRE_DIR="$BUILD_DIR/lustre-release"

# # Create build directories
# mkdir -p "$BUILD_DIR"
# cd "$BUILD_DIR"

# # Download and extract the Linux kernel
# echo "Downloading and extracting Linux kernel $KERNEL_VERSION..."
# wget "$KERNEL_URL"
# tar -xf "linux-$KERNEL_VERSION.tar.xz"

# # Clone the Lustre repository
# echo "Cloning Lustre repository..."
# git clone "$LUSTRE_REPO" "$LUSTRE_DIR"
# cd "$LUSTRE_DIR"
# git checkout "$LUSTRE_BRANCH"

# # Clone the ZFS repository
# echo "Cloning ZFS repository..."
# git clone "$ZFS_REPO" "$BUILD_DIR/zfs"
# cd "$BUILD_DIR/zfs"
# git checkout "$ZFS_BRANCH"

# Build and install ZFS
echo "Building and installing ZFS..."
./autogen.sh
./configure --with-linux="$KERNEL_DIR" --with-linux-obj="$KERNEL_DIR"
make -j"$(nproc)"
# sudo make install

# Prepare kernel source for Lustre
echo "Preparing kernel source for Lustre..."
cd "$LUSTRE_DIR"
sh autogen.sh
./configure --with-linux="$KERNEL_DIR" --with-zfs="$BUILD_DIR/zfs" # --with-spl="$BUILD_DIR/spl"

# Build Lustre
echo "Building Lustre..."
make -j"$NUM_CORES" rpms

echo "Lustre build complete. RPMs are in $LUSTRE_DIR"
