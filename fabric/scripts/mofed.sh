#!/bin/bash

# Function to install OFED on Ubuntu
install_ubuntu() {
  ubuntu_release=$(awk -F '"' '/VERSION_ID/ {print $2}' /etc/os-release)
  mofed_repo_base_url="https://linux.mellanox.com/public/repo/mlnx_ofed"
  mofed_repo_gpg_url="https://www.mellanox.com/downloads/ofed/RPM-GPG-KEY-Mellanox"
  ubuntu_repo_dist_name="ubuntu${ubuntu_release}"
  ubuntu_repo_file_name="mellanox_mlnx_ofed.list"
  ubuntu_repo_file_path="/etc/apt/sources.list.d/${ubuntu_repo_file_name}"
  echo "Adding apt key..."
  wget -qO - ${mofed_repo_gpg_url} | apt-key add -
  url="${mofed_repo_base_url}/latest/${ubuntu_repo_dist_name}/${ubuntu_repo_file_name}"
  wget -qO ${ubuntu_repo_file_path} "${url}"
  chmod 644 ${ubuntu_repo_file_path}
  echo "Updating apt cache..."
  apt update -y
  echo "Installing packages..."
  OFED_PKGS=(libc6-dev
    mlnx-ofed-kernel-dkms
    mlnx-ofed-kernel-utils
    mlnx-ofed-basic
    rdma-core
    ibverbs-utils
    ibverbs-providers
  )
  apt install -y ${OFED_PKGS[@]}
  echo "Configuring IB devices..."
  systemctl restart openibd
}

# Function to install OFED on RHEL/CentOS/Oracle Linux
install_rhel() {
  rhel_release=$(awk -F '"' '/VERSION_ID/ {print $2}' /etc/os-release | cut -d '.' -f1)
  mofed_repo_base_url="https://linux.mellanox.com/public/repo/mlnx_ofed"
  rhel_repo_dist_name="rhel${rhel_release}.x"
  rhel_repo_file_name="mellanox_mlnx_ofed.repo"
  rhel_repo_file_path="/etc/yum.repos.d/${rhel_repo_file_name}"
  url="${mofed_repo_base_url}/latest/${rhel_repo_dist_name}/${rhel_repo_file_name}"
  wget -qO ${rhel_repo_file_path} "${url}"
  echo "Installing packages..."
  OFED_PKGS=(libc6-dev
    mlnx-ofed-kernel-dkms
    mlnx-ofed-kernel-utils
    mlnx-ofed-basic
    rdma-core
    ibverbs-utils
    ibverbs-providers
  )
  yum install -y ${OFED_PKGS[@]}
  echo "Configuring IB devices..."
  systemctl restart openibd
}

# Function to install OFED on SUSE Linux Enterprise Server (SLES)
install_sles() {
  sles_release=$(awk -F '=' '/VERSION_ID/ {print $2}' /etc/os-release)
  mofed_repo_base_url="https://linux.mellanox.com/public/repo/mlnx_ofed"
  sles_repo_dist_name="sles${sles_release}"
  sles_repo_file_name="mellanox_mlnx_ofed.repo"
  sles_repo_file_path="/etc/zypp/repos.d/${sles_repo_file_name}"
  url="${mofed_repo_base_url}/latest/${sles_repo_dist_name}/${sles_repo_file_name}"
  wget -qO ${sles_repo_file_path} "${url}"
  echo "Installing packages..."
  OFED_PKGS=(libc6-dev
    mlnx-ofed-kernel-dkms
    mlnx-ofed-kernel-utils
    mlnx-ofed-basic
    rdma-core
    ibverbs-utils
    ibverbs-providers
  )
  zypper install -y ${OFED_PKGS[@]}
  echo "Configuring IB devices..."
  systemctl restart openibd
}

# Detect the Linux distribution and call the appropriate function
if [ -f /etc/os-release ]; then
  . /etc/os-release
  case $ID in
    ubuntu)
      install_ubuntu
      ;;
    rhel|centos|ol)
      install_rhel
      ;;
    sles)
      install_sles
      ;;
    *)
      echo "Unsupported Linux distribution: $ID"
      exit 1
      ;;
  esac
else
  echo "Unable to determine the Linux distribution."
  exit 1
fi

