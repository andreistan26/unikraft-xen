#!/bin/bash
#
# Install script for Xen 4.17 on Ubuntu 22.04 

# Check dom0 kernel config
if [ `grep -i "CONFIG_XEN_DOM0=y" /boot/config-$(uname -r)` ]; then
	echo "Dom0 kernel config is OK"
else
	echo "Current kernel is not configured for Xen dom0 support"
	exit 1
fi

read -r -p "Install Deps? [y/N] " response
case "$response" in
	[yY][eE][sS]|[yY]) 
		rc = `sudo apt install bc bcc bin86 gawk bridge-utils iproute2 libcurl4 libcurl4-openssl-dev bzip2 kmod fig2dev texinfo texlive-latex-base gcc-multilib texlive-fonts-extra \
		 texlive-fonts-recommended libpci-dev mercurial libncurses5-dev patch libvncserver-dev libsdl1.2-dev gettext libaio1 libaio-dev libssl-dev acpica-tools \
		 libbz2-dev git uuid-dev python-is-python3 python-dev-is-python3 python3-twisted  \
		 build-essential make gcc libc6-dev zlib1g-dev texlive-latex-recommended libext2fs-dev libyajl-dev libpixman-1-dev liblzma-dev flex bison ninja-build libelf-dev \
		 libnl-3-dev libnl-route-3-dev \
		 libsystemd-dev \
		 iasl libbz2-dev e2fslibs-dev git-core uuid-dev ocaml ocaml-findlib libx11-dev bison flex xz-utils libyajl-dev \
		 libsdl1.2-dev \
		 # For 9pfs support
		 libcap-ng-dev libattr1-dev`
		if [ $rc -ne 0 ]; then
			echo "Error installing deps"
			exit 1
		fi
		;;
	*)
		echo "Skipping Deps"
		;;
esac


git clone git://xenbits.xen.org/xen.git
cd xen
git checkout stable-4.17

# configure XEN
./configure --enable-systemd --enable-9pfs
make dist -j$(nproc)
sudo make install

# reload dynamic linker
/sbin/ldconfig

# update grub
sudo update-grub

sudo systemctl enable xen-qemu-dom0-disk-backend.service
sudo systemctl enable xen-init-dom0.service
sudo systemctl enable xenconsoled.service

sudo systemctl enable xendomains.service
sudo systemctl enable xen-watchdog.service
sudo systemctl enable xendriverdomain.service

sudo echo "GRUB_CMDLINE_XEN_DEFAULT=dom0_mem=4096M,max:4096M" >> /etc/default/grub
sudo echo "GRUB_CMDLINE_XEN=" >> /etc/default/grub

sudo sed -i 's/GRUB_TIMEOUT=0/GRUB_TIMEOUT=5/g' /etc/default/grub
sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"/GRUB_CMDLINE_LINUX_DEFAULT="quite"/g' /etc/default/grub
sudo update-grub
