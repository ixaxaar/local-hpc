#!/bin/bash

###################################################################
# Fetch and build lustre client and server, supports both LDISKFS and ZFS builds
###################################################################
# Example usage:
# ./compile_lustre.sh \
#     -d ./build \
#     -k ../../kernel/linux-6.9.3 \
#     -s 5.14-rhel9.3

# Exit immediately if a command exits with a non-zero status
set -e

# Function to display usage
usage() {
    echo "Usage: $0 -d <build_directory> -k <kernel_source_directory> -s <series>"
    exit 1
}

# Parse command line arguments
while getopts "d:k:s:" opt; do
    case "${opt}" in
        d)
            BUILD_DIR=${OPTARG}
            ;;
        k)
            KERNEL_DIR=${OPTARG}
            ;;
        s)
            SERIES=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done

# Check if all parameters are provided
if [ -z "${BUILD_DIR}" ] || [ -z "${KERNEL_DIR}" ] || [ -z "${SERIES}" ]; then
    usage
fi


ZFS_VERSION=2.2.4
LUSTRE_VERSION=2.15.63
OFED_VERSION=5.3-daily
KERNEL_DIR=../../../kernel/linux-6.9.3

# Download and prepare zfs sources
cd "$BUILD_DIR"
wget https://github.com/openzfs/zfs/releases/download/zfs-"${ZFS_VERSION}"/zfs-"${ZFS_VERSION}".tar.gz
tar -xvf zfs-"${ZFS_VERSION}".tar.gz

# Download and prepare OFED sources
cd "$BUILD_DIR"
wget https://downloads.openfabrics.org/OFED/ofed-"${OFED_VERSION}"/latest.tgz
tar -xvf latest.tgz
cd OFED-5.3-20191018-2019
# ask the user if they'd like to install OFED, if yes, this interactive step ensues
sudo ./install.pl --linux ../../../kernel/linux-6.9.3 --kernel 6.9.3


# Download and prepare Intel IB driver sources
cd "$BUILD_DIR"
if [ "$DISTRO" == "rhel" ]    # ← see 'man test' for available unary and binary operators.
then
    wget https://downloadmirror.intel.com/818023/Intel-Basic-IB.RHEL93-x86_64.11.6.0.0.231.tgz
    tar -xvf Intel-Basic-IB.RHEL93-x86_64.11.6.0.0.231.tgz
elif [ "$DISTRO" == "ubuntu" ]
then
    wget https://downloadmirror.intel.com/818023/Intel-Basic-IB.UBUNTU2204-x86_64.11.6.0.0.231.tgz
else
    echo "Distribution does not have packages for intel Basic IB"
fi

# Download and prepare Mellanox OFED sources
wget https://www.mellanox.com/downloads/ofed/MLNX_OFED-24.04-0.6.6.0/MLNX_OFED_SRC-24.04-0.6.6.0.tgz


# Download and prepare lustre sources
git clone https://github.com/lustre/lustre-release.git
cd lustre-release
git checkout "${LUSTRE_VERSION}"
sh autogen.sh
./configure \
    --enable-server \
    --disable-ldiskfs \
    --with-linux="${KERNEL_DIR}" \
    --with-zfs=../zfs-"${ZFS_VERSION}"












# Function to apply kernel patches from the Lustre repository
apply_kernel_patches() {
    echo "Applying kernel patches for series: ${SERIES}..."

    # Clone the Lustre repository
    cd "${BUILD_DIR}"
    git clone https://github.com/lustre/lustre-release.git
    cd lustre-release

    # Construct the patch file
    PATCH_FILE="${BUILD_DIR}/patch-lustre.patch"
    > "${PATCH_FILE}"

    for i in $(cat "lustre/kernel_patches/series/${SERIES}.series"); do
        cat "lustre/kernel_patches/patches/${i}" >> "${PATCH_FILE}"
    done

    # Apply the patch to the kernel
    cd "${KERNEL_DIR}"
    patch -p1 < "${PATCH_FILE}"

    echo "Kernel patches applied."
}

# Function to compile Lustre with ldiskfs
compile_ldiskfs() {
    echo "Compiling Lustre with ldiskfs support..."

    # Change to kernel source directory
    cd "${KERNEL_DIR}"

    # Compile the kernel
    echo "Compiling the kernel..."
    make olddefconfig
    make -j$(nproc)
    make modules_install
    make install

    # Change to Lustre source directory
    cd "${BUILD_DIR}/lustre-release"

    # Compile Lustre with ldiskfs
    ./configure --with-o2ib=/usr --enable-server --disable-zfs --with-linux="${KERNEL_DIR}"
    make -j$(nproc)
    make install

    echo "Lustre compiled with ldiskfs support."
}

# Function to compile Lustre with ZFS
compile_zfs() {
    echo "Compiling Lustre with ZFS support..."

    # Change to build directory
    cd "${BUILD_DIR}"

    # Clone the ZFS repository
    echo "Cloning ZFS repository..."
    git clone https://github.com/openzfs/zfs.git
    cd zfs

    # Checkout the latest stable release
    echo "Checking out the latest stable release of ZFS..."
    git checkout $(git describe --abbrev=0 --tags)

    # Configure and compile ZFS
    ./configure
    make -j$(nproc)
    make install

    # Load ZFS kernel modules
    echo "Loading ZFS kernel modules..."
    modprobe zfs

    # Change to Lustre source directory
    cd "${BUILD_DIR}/lustre-release"

    # Compile Lustre with ZFS
    ./configure --with-o2ib=/usr --enable-server --with-zfs=/usr/local --with-linux="${KERNEL_DIR}"
    make -j$(nproc)
    make install

    echo "Lustre compiled with ZFS support."
}

# Main script execution
echo "Starting Lustre compilation process..."

# Apply kernel patches
apply_kernel_patches

# Compile Lustre with ldiskfs
compile_ldiskfs

# Compile Lustre with ZFS
compile_zfs

echo "Lustre compilation process completed."

