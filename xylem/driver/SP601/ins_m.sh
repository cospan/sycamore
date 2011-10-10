#!/bin/bash
#
#

DIRECTORY=/lib/modules/`uname -r`/kernel/drivers/pci


if [ "$(id -u)" != "0" ]; then
	echo "Must be root to run this script" 1>&2
	exit 1
fi

if [ ! -d "$DIRECTORY" ]; then
	echo "Creating framebuffer directory"
	mkdir "$DIRECTORY"
fi

echo "copying kernel module"

cp *.ko "$DIRECTORY"/

echo "updating dependancies"

depmod -a

