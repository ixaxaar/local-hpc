#!/bin/bash

###############################################################
# Fetch and build the kernel
###############################################################
# Example usage:
# ./compile.sh -d rhel \
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
  echo "Usage: $0 [-d <distribution>] [-v <kernel_version>] [-c <config_option>] [-b <build_dir>] [-m]"
  echo "  -d <distribution>     Specify the distribution (e.g., rhel, ubuntu, rocky, arch) to use its source package"
  echo "  -v <kernel_version>   Specify the Linux kernel version to fetch and compile (only applicable for vanilla kernel)"
  echo "  -c <config_option>    Specify a custom kernel config option (can be used multiple times)"
  echo "  -m                    Invoke make *-config based on the environment after make olddefconfig"
  exit 1
}

# Parse command-line arguments
while getopts ":d:v:c:m" opt; do
  case $opt in
  d) distribution="$OPTARG" ;;
  v) kernel_version="$OPTARG" ;;
  c) config_options+=("$OPTARG") ;;
  m) invoke_make_config=false ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    ;;
  :)
    echo "Option -$OPTARG requires an argument." >&2
    usage
    ;;
  esac
done

# Check if distribution or kernel version is provided
if [ -z "$distribution" ] && [ -z "$kernel_version" ]; then
  echo "Please provide either a distribution using the -d option or a Linux kernel version using the -v option."
  usage
fi

# Download the kernel source based on the distribution or kernel version
if [ -n "$distribution" ]; then
  case $distribution in
  rhel)
    # Download RHEL kernel source package
    yum install -y kernel-devel
    kernel_dir="/usr/src/kernels/$(uname -r)"
    ;;
  ubuntu)
    # Download Ubuntu kernel source package
    apt-get install -y linux-source
    kernel_dir="/usr/src/linux-source-$(uname -r | cut -d'-' -f1)"
    ;;
  rocky)
    # Download Rocky Linux kernel source package
    dnf install -y kernel-devel
    kernel_dir="/usr/src/kernels/$(uname -r)"
    ;;
  arch)
    # Download Arch Linux kernel source package
    pacman -S --noconfirm linux-headers
    kernel_dir="/usr/lib/modules/$(uname -r)/build"
    ;;
  *)
    echo "Unsupported distribution: $distribution"
    exit 1
    ;;
  esac
else
  # Download the specified Linux kernel version
  kernel_dir=$(pwd)"/linux-$kernel_version"
  wget https://cdn.kernel.org/pub/linux/kernel/v"${kernel_version%%.*}".x/linux-"$kernel_version".tar.xz
  tar xf linux-"$kernel_version".tar.xz
fi

# Copy the current running kernel's .config file
cd "${kernel_dir}" || exit
cat /proc/config.gz | gunzip >.config

# Update the .config file with the custom config options
for option in "${config_options[@]}"; do
  ./scripts/config --set-str "$option"
done

# Set defaults for new config options
make olddefconfig

# Invoke make *-config based on the environment if the -m option is provided
# Warning: this part is interactive
if [ "$invoke_make_config" = true ]; then
  if [ "$XDG_SESSION_TYPE" = "x11" ]; then
    # X11 environment detected
    make xconfig
  elif [ "$XDG_SESSION_TYPE" = "wayland" ]; then
    # Wayland environment detected
    make gconfig
  elif [ -n "$DISPLAY" ]; then
    # X11 environment detected (fallback)
    make xconfig
  else
    # Non-graphical environment
    make menuconfig
  fi
fi

# Compile the Linux kernel
# shellcheck disable=SC2046
make -j$(nproc)

echo "Linux kernel compiled successfully."
ls -lah vmlinux
