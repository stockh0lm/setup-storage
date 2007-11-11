#!/usr/bin/perl -w

#*********************************************************************
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# A copy of the GNU General Public License is available as
# `/usr/share/common-licences/GPL' in the Debian GNU/Linux distribution
# or on the World Wide Web at http://www.gnu.org/copyleft/gpl.html. You
# can also obtain it by writing to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#*********************************************************************

use strict;

################################################################################
#
# @file init.pm
#
# @brief Initialize all variables and acquire the set of disks of the system.
#
# The layout of the data structures is documented in the wiki:
# http://faiwiki.debian.net/index.php/Storage_Magic
#
# $Id$
#
# @author Christian Kern, Michael Tautschnig
# @date Sun Jul 23 16:09:36 CEST 2006
#
################################################################################

package FAI;

################################################################################
#
# @brief Enable debugging by setting $debug to a value greater than 0
#
################################################################################
$FAI::debug = 0;
defined( $ENV{debug} ) and $FAI::debug = $ENV{debug};

################################################################################
#
# @brief The lists of disks of the system
#
################################################################################
@FAI::disks = split( /\n/, $ENV{disklist} );
( $FAI::debug > 0 ) and print "disklist was:\n" . $ENV{disklist};

################################################################################
#
# @brief The variables later written to disk_var.sh
#
################################################################################
%FAI::disk_var = ();
$FAI::disk_var{"SWAPLIST"} = "";

################################################################################
#
# @brief A flag to tell our script that the system is not installed for the
# first time
#
################################################################################
$FAI::reinstall = 1;
defined( $ENV{fl_initial} ) and $FAI::reinstall = 0;

################################################################################
#
# @brief The hash of all configurations specified in the disk_config file
#
################################################################################
%FAI::configs = ();

################################################################################
#
# @brief The current disk configuration
#
################################################################################
%FAI::current_config = ();

################################################################################
#
# @brief The current LVM configuration
#
################################################################################
%FAI::current_lvm_config = ();

################################################################################
#
# @brief The current RAID configuration
#
################################################################################
%FAI::current_raid_config = ();

################################################################################
#
# @brief The list of commands to be executed
#
################################################################################
@FAI::commands = ();

1;

