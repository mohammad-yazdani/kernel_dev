#!/bin/bash

apt-get -y install libncurses-dev gawk flex bison openssl libssl-dev dkms libelf-dev libudev-dev libpci-dev libiberty-dev autoconf git

echo "deb-src http://archive.ubuntu.com/ubuntu focal main" >> /etc/apt/sources.list
echo "deb-src http://archive.ubuntu.com/ubuntu focal-updates main" >> /etc/apt/sources.list
apt update
apt-get -y build-dep linux linux-image-$(uname -r)

