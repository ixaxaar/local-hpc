#!/bin/bash

###############################################################
# Prepare the OS for builds
###############################################################

# Determine package manager
install_packages() {
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y \
            asciidoc automake bc binutils bison \
            flex gcc git libelf-dev libssl-dev \
            libtool libuuid1 libncurses5-dev \
            make patch python3-dev \
            wget xmlto zlib1g-dev \
            uuid-dev libblkid-dev libselinux1-dev
    elif command -v yum &> /dev/null; then
        sudo yum groupinstall -y "Development Tools"
        sudo yum install -y \
            asciidoc automake bc binutils-devel bison \
            elfutils-libelf-devel flex gcc gcc-c++ \
            git hmaccalc keyutils-libs-devel krb5-devel \
            libattr-devel libblkid-devel libselinux-devel \
            libtool libuuid-devel lsscsi make ncurses-devel \
            patchutils pciutils-devel pesign python3-devel \
            rpm-build systemd-devel tcl tcl-devel tk tk-devel \
            wget xmlto zlib-devel
    elif command -v zypper &> /dev/null; then
        sudo zypper install -y \
            asciidoc automake bc binutils-devel bison \
            elfutils-libelf-devel flex gcc gcc-c++ \
            git hmaccalc keyutils-libs-devel krb5-devel \
            libattr1 libblkid1 libselinux1 libtool libuuid1 \
            lsscsi make ncurses-devel patchutils pciutils-devel \
            pesign python3-devel rpm-build systemd-devel tcl tk \
            wget xmlto zlib-devel
    elif command -v pacman &> /dev/null; then
        sudo pacman -Syy --noconfirm
        sudo pacman -S --noconfirm \
            asciidoc automake bc binutils bison \
            elfutils flex gcc git \
            keyutils krb5 libelf \
            libtool libutil-linux lsscsi make \
            ncurses patchutils pciutils pesign \
            python python-pip python-setuptools \
            tk wget xmlto zlib
    else
        echo "Unsupported package manager. Install dependencies manually."
        exit 1
    fi
}

# Prepare build environment
echo "Preparing build environment..."
install_packages
