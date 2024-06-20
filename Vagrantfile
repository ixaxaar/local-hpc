Vagrant.configure("2") do |config|
  # Define the base box for each operating system

  config.vm.define "ubuntu" do |config|
    config.vm.box = "bento/ubuntu-24.04"
    config.vm.box_architecture = "amd64"
    config.vm.box_version = "202404.26.0"
  end

  config.vm.define "ubuntu-arm" do |config|
    config.vm.box = "bento/ubuntu-24.04"
    config.vm.box_architecture = "arm64"
    config.vm.box_version = "202404.26.0"
  end

  config.vm.define "rhel" do |config|
    config.vm.box = "generic/rhel9"
    config.vm.box_architecture = "amd64"
    config.vm.box_version = "4.3.12"
  end

  config.vm.define "rhel-arm" do |config|
    config.vm.box = "generic-a64/rhel9"
    config.vm.box_architecture = "arm64"
    config.vm.box_version = "4.3.12"
  end

  config.vm.define "rocky" do |config|
    config.vm.box = "rockylinux/9"
    config.vm.box_architecture = "amd64"
    config.vm.box_version = "4.0.0"
  end

  config.vm.define "rocky-arm" do |config|
    config.vm.box = "rockylinux/9"
    config.vm.box_architecture = "arm64"
    config.vm.box_version = "4.0.0"
  end

  # We do custom shit here 😈
  config.vm.define "arch" do |config|
    config.vm.box = "archlinux/archlinux"
    config.vm.box_architecture = "amd64"
    config.vm.box_version = "20240601.239419"
  end

  # Define the VM resources
  config.vm.provider "virtualbox" do |v|
      v.memory = 4096
      v.cpus = 4
  end

  config.vm.disk :disk, size: "20GB", primary: true
end
