#!/usr/bin/env bash

# install netmap.ko to a systemd system

NETMAP_KO_PATH="$1"

set -e

TMPDIR=$(mktemp -d -p '')
echo netmap > $TMPDIR/netmap.conf
install -m 644 $TMPDIR/netmap.conf /etc/modules-load.d
install -m 755 $NETMAP_KO_PATH /lib/modules/$(uname -r)/kernel/drivers/netmap

/sbin/depmod
modprobe netmap
