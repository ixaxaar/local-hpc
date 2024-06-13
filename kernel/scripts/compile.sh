#!/bin/bash

###############################################################
# Fetch and build the kernel
###############################################################
# Example usage:
# ./compile.sh -v 6.9.4 -b ../build \
#   -c INFINIBAND=m \
#   -c INFINIBAND_USER_MAD=m \
#   -c INFINIBAND_USER_ACCESS=m \
#   -c INFINIBAND_ADDR_TRANS=m \
#   -c INFINIBAND_ADDR_TRANS_CONFIGFS=m \
#   -c INFINIBAND_IPOIB=m \
#   -c INFINIBAND_IPOIB_CM=m \
#   -c INFINIBAND_IPOIB_DEBUG=m \
#   -c INFINIBAND_SRP=m \
#   -c INFINIBAND_ISER=m \
#   -c RDMA_RXE=m \
#   -c RDMA_CM=m \
#   -c NFSD=m \
#   -c NFS_FS=m \
#   -c CONFIG_NUMA=y \
#   -c CONFIG_TRANSPARENT_HUGEPAGE=y \
#   -c CONFIG_CGROUP_HUGETLB=y \
#   -c CONFIG_CGROUP_PIDS=y \
#   -c CONFIG_CGROUP_RDMA=y \
#   -c MLX5_CORE=m \
#   -c MLX5_CORE_EN=m \
#   -c MLX5_FPGA=m \
#   -c MLX5_IPSEC=m \
#   -c MLX5_TLS=m \
#   -c MLX5_VDPA=m \
#   -c TUN=m \
#   -c CONFIG_VFIO=y \
#   -c CONFIG_VFIO_PCI=y \
#   -c CONFIG_VFIO_NOIOMMU=y \
#   -c CONFIG_VFIO_MDEV=y

# Function to display usage instructions
usage() {
  echo "Usage: $0 [-v <kernel_version>] [-c <config_option>] [-b <build_dir>]"
  echo "  -v <kernel_version>   Specify the Linux kernel version to fetch and compile"
  echo "  -c <config_option>    Specify a custom kernel config option (can be used multiple times)"
  echo "  -b <build_dir>        Specify the build directory (default: linux-<kernel_version>-build)"
  exit 1
}

# Parse command-line arguments
while getopts ":v:c:b:" opt; do
  case $opt in
    v) kernel_version="$OPTARG";;
    c) config_options+=("$OPTARG");;
    b) build_dir="$OPTARG";;
    \?) echo "Invalid option: -$OPTARG" >&2; usage;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage;;
  esac
done

# Check if kernel version is provided
if [ -z "$kernel_version" ]; then
  echo "Please provide a Linux kernel version using the -v option."
  usage
fi

# Set default build directory if not provided
if [ -z "$build_dir" ]; then
  build_dir="linux-$kernel_version-build"
fi
build_dir=$(pwd)"/${build_dir}"

# # Download the specified Linux kernel version
kernel_dir=$(pwd)"/linux-$kernel_version"
wget https://cdn.kernel.org/pub/linux/kernel/v"${kernel_version%%.*}".x/linux-"$kernel_version".tar.xz
tar xf linux-"$kernel_version".tar.xz

# Create the build directory
mkdir -p "$build_dir"

# Copy the current running kernel's .config file
cd "${kernel_dir}" || exit
cat /proc/config.gz | gunzip > .config

# Update the .config file with the custom config options
for option in "${config_options[@]}"; do
  ./scripts/config --set-str "$option"
done

# Set defaults for new config options
make O="${build_dir}" olddefconfig

# Compile the Linux kernel
# shellcheck disable=SC2046
make O="${build_dir}" -j$(nproc)

echo "Linux kernel $kernel_version compiled and installed successfully in $build_dir."
