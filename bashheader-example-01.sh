#!/bin/sh -e
#
# source distribution: CentOS release 6.7 (Final)
# source from: /lib/udev/write_net_rules
#
# Copyright (C) 2006 Marco d'Itri <md@Linux.IT>
# Copyright (C) 2007 Kay Sievers <kay.sievers@vrfy.org>
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation version 2 of the License.
#
# This script is run to create persistent network device naming rules
# based on properties of the device.
# If the interface needs to be renamed, INTERFACE_NEW=<name> will be printed
# on stdout to allow udev to IMPORT it.

# variables used to communicate:
#   MATCHADDR             MAC address used for the match
#   MATCHID               bus_id used for the match
#   MATCHDEVID            dev_id used for the match
#   MATCHDRV              driver name used for the match
#   MATCHIFTYPE           interface type match
#   COMMENT               comment to add to the generated rule
#   INTERFACE_NAME        requested name supplied by external tool
#   INTERFACE_NEW         new interface name returned by rule writer

# debug, if UDEV_LOG=<debug>
if [ -n "$UDEV_LOG" ]; then
	if [ "$UDEV_LOG" -ge 7 ]; then
		set -x
	fi
fi
