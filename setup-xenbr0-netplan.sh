#!/bin/bash

# make it with command line parameters
# eth, ip, default_gw, dns

eth=""
# ip with netmask
ip=""
# ip without netmask
default_gw=""
# comma separated list of dns servers
dns="[1.1.1.1,8.8.8.8]"

while getopts e:i:g:d: option
do
case "${option}"
in
	e) eth=${OPTARG};;
	i) ip=${OPTARG};;
	g) default_gw=${OPTARG};;
	d) dns=${OPTARG};;
esac
done

if [ -z "$eth" ] || [ -z "$ip" ] || [ -z "$default_gw" ]
then
	echo "Usage: setup-xenbr0-netplan.sh -e eth -i ip -g default_gw [-d dns]"
	exit 1
fi

# check if networkd is used or NetworkManager
if [ `systemctl status NetworkManager | grep -c "Active: active"` -eq 1 ]
then
	# disable NetworkManager and enable systemd-networkd
	sudo systemctl stop NetworkManager
	sudo systemctl disable NetworkManager
	sudo systemctl enable systemd-networkd 
fi


sudo echo "network:
  renderer: networkd
  version: 2
  ethernets:
    "$eth":
      dhcp4: no
      dhcp6: no
  bridges:
    xenbr0:
      addresses: ["$ip"]
      routes:
      - to: default
        via: "$default_gw"
      nameservers:
        addresses: ["$dns"]
      dhcp4: no
      dhcp6: no
      interfaces:
        - "$eth"
" >> /etc/netplan/00-netcfg.yaml

netplan apply
