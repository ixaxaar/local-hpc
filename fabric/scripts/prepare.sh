#!/bin/bash

# Detect the package manager
if command -v apt-get >/dev/null 2>&1; then
    PKG_MGR="apt-get"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MGR="dnf"
elif command -v yum >/dev/null 2>&1; then
    PKG_MGR="yum"
elif command -v zypper >/dev/null 2>&1; then
    PKG_MGR="zypper"
elif command -v pacman >/dev/null 2>&1; then
    PKG_MGR="pacman"
else
    echo "Unsupported package manager"
    exit 1
fi

# Function to detect RHEL version
detect_rhel_version() {
    if [ -f /etc/redhat-release ]; then
        grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | cut -d'.' -f1
    else
        echo "Unable to detect RHEL version"
        exit 1
    fi
}

# Install CUDA and drivers based on the package manager
case "$PKG_MGR" in
apt-get)
    # Install prerequisites
    sudo apt-get update
    sudo apt-get install -y linux-headers-$(uname -r)

    # Add CUDA repository
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(lsb_release -sr | sed 's/\.//')/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    echo "deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/ubuntu$(lsb_release -sr | sed 's/\.//')/x86_64/ /" | sudo tee /etc/apt/sources.list.d/cuda-$(lsb_release -sr | sed 's/\.//')-x86_64.list

    # Install CUDA and drivers
    sudo apt-get update
    sudo apt-get install -y cuda-toolkit cuda-drivers
    ;;

dnf | yum)
    # Install prerequisites
    # WARNING: requires license for RHEL
    # TODO: for rhel only!
    # sudo $PKG_MGR install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm
    # sudo subscription-manager repos --enable=rhel-9-for-x86_64-appstream-rpms
    # sudo subscription-manager repos --enable=rhel-9-for-x86_64-baseos-rpms
    # sudo subscription-manager repos --enable=codeready-builder-for-rhel-9-x86_64-rpms
    sudo dnf config-manager --set-enabled crb
    sudo dnf install epel-release

    sudo $PKG_MGR update -y

    sudo $PKG_MGR install -y kernel-devel kernel-headers

    # Detect RHEL version
    RHEL_VERSION=$(detect_rhel_version)

    # Add CUDA repository
    sudo $PKG_MGR config-manager --add-repo https://developer.download.nvidia.com/compute/cuda/repos/rhel"${RHEL_VERSION}"/x86_64/cuda-rhel"${RHEL_VERSION}".repo

    # Install CUDA and drivers
    sudo $PKG_MGR clean expire-cache
    sudo $PKG_MGR module install nvidia-driver:latest-dkms
    sudo $PKG_MGR install -y cuda-toolkit
    ;;

zypper)
    # Install prerequisites
    sudo zypper install -y lsb-release
    sudo zypper install -y kernel-default-devel=$(uname -r | sed 's/\-default//')

    # Add CUDA repository
    sudo zypper addrepo https://developer.download.nvidia.com/compute/cuda/repos/sles$(lsb_release -sr | sed 's/\.//')/x86_64/cuda-sles$(lsb_release -sr | sed 's/\.//').repo

    # Install CUDA and drivers
    sudo zypper refresh
    sudo zypper install -y cuda-toolkit cuda-drivers
    ;;

pacman)
    # Install prerequisites
    sudo pacman -Sy linux-headers

    # Add CUDA repository
    sudo sh -c 'echo "[cuda]" > /etc/pacman.conf'
    sudo sh -c 'echo "Server = https://developer.download.nvidia.com/compute/cuda/repos/arch/x86_64" >> /etc/pacman.conf'
    sudo sh -c 'echo "SigLevel = Optional TrustAll" >> /etc/pacman.conf'

    # Install CUDA and drivers
    sudo pacman -Sy cuda cuda-tools
    ;;

*)
    echo "Unsupported package manager: $PKG_MGR"
    exit 1
    ;;
esac
