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
# @file fstab.pm
#
# @brief Generate an fstab file as appropriate for the configuration
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
# @brief Create a line for /etc/fstab
#
# @reference $d_ref Device reference
# @param $name Device name used as a key in /etc/fstab
# @param $dev_name Real (current) device name to be used in SWAPLIST
#
# @return fstab line
#
################################################################################
sub create_fstab_line {
  my ($d_ref, $name, $dev_name) = @_;

  my @fstab_line = ();

  # start with the device key
  push @fstab_line, $name;

  # add mount information, never dump, order of filesystem checks
  push @fstab_line, ($d_ref->{mountpoint}, $d_ref->{filesystem},
    $d_ref->{mount_options}, 0, 2);
  # order of filesystem checks: the root filesystem gets a 1, the others
  # got 2
  $fstab_line[-1] = 1 if ($d_ref->{mountpoint} eq "/");

  # set the ROOT_PARTITION variable, if this is the mountpoint for /
  $FAI::disk_var{ROOT_PARTITION} = $name
    if ($d_ref->{mountpoint} eq "/");

  # add to the swaplist, if the filesystem is swap
  $FAI::disk_var{SWAPLIST} .= " " . $dev_name
    if ($d_ref->{filesystem} eq "swap");

  # join the columns of one line with tabs
  return join ("\t", @fstab_line);
}

################################################################################
#
# @brief this function generates the fstab file from our representation of the
# partitions to be created.
#
# @reference config Reference to our representation of the partitions to be
# created
#
# @return list of fstab lines
#
################################################################################
sub generate_fstab {

  # config structure is the only input
  my ($config) = @_;

  # the file to be returned, a list of lines
  my @fstab = ();
      
  # walk through all configured parts
  # the order of entries is most likely wrong, it is fixed at the end
  foreach my $c (keys %$config) {

    # entry is a physical device
    if ($c =~ /^PHY_(.+)$/) {
      my $device = $1;

      # make sure the desired fstabkey is defined at all
      defined ($config->{$c}->{fstabkey})
        or &FAI::internal_error("fstabkey undefined");

      # create a line in the output file for each partition
      foreach my $p (keys %{ $config->{$c}->{partitions} }) {

        # keep a reference to save some typing
        my $p_ref = $config->{$c}->{partitions}->{$p};

        # skip extended partitions and entries without a mountpoint
        next if ($p_ref->{size}->{extended} || $p_ref->{mountpoint} eq "-");
  
        my $device_name = &FAI::make_device_name($device, $p_ref->{number});
        if ($p_ref->{encrypt}) {
          # encryption requested, rewrite the device name
          $device_name =~ "s#/#_#g";
          $device_name = "/dev/mapper/crypt$device_name";
        }

        # device key used for mounting
        my $fstab_key = "";

        # write the device name as the first entry; if the user prefers uuids
        # or labels, use these if available
        my @uuid = ();
        &FAI::execute_ro_command(
          "/lib/udev/vol_id -u $device_name", \@uuid, 0);

        # every device must have a uuid, otherwise this is an error (unless we
        # are testing only)
        ($FAI::no_dry_run == 0 || scalar (@uuid) == 1)
          or die "Failed to obtain UUID for $device_name\n";

        # get the label -- this is likely empty
        my @label = ();
        &FAI::execute_ro_command(
          "/lib/udev/vol_id -l $device_name", \@label, 0);

        # using the fstabkey value the desired device entry is defined
        if ($config->{$c}->{fstabkey} eq "uuid") {
          chomp ($uuid[0]);
          $fstab_key = "UUID=$uuid[0]";
        } elsif ($config->{$c}->{fstabkey} eq "label" && scalar(@label) == 1) {
          chomp($label[0]);
          $fstab_key = "LABEL=$label[0]";
        } else {
          # otherwise, use the usual device path
          $fstab_key = $device_name;
        }
          
        # if the mount point is / or /boot, the variables should be set, unless
        # they are already
        if ($p_ref->{mountpoint} eq "/boot" || ($p_ref->{mountpoint} eq "/" && 
              !defined ($FAI::disk_var{BOOT_PARTITION}))) {
          # set the BOOT_DEVICE and BOOT_PARTITION variables, if necessary
          $FAI::disk_var{BOOT_PARTITION} = $device_name;
          ($c =~ /^PHY_(.+)$/) or &FAI::internal_error("unexpected mismatch");
          defined ($FAI::disk_var{BOOT_DEVICE}) or
            $FAI::disk_var{BOOT_DEVICE} = $1;
        }
  
        push @fstab, &FAI::create_fstab_line($p_ref, $fstab_key, $device_name);

      }
    } elsif ($c =~ /^VG_(.+)$/) {
      my $device = $1;

      # create a line in the output file for each logical volume
      foreach my $l (keys %{ $config->{$c}->{volumes} }) {

        # keep a reference to save some typing
        my $l_ref = $config->{$c}->{volumes}->{$l};

        # skip entries without a mountpoint
        next if ($l_ref->{mountpoint} eq "-");

        # real device name
        my @fstab_key = ();

        # resolve the symlink to the real device
        # and write it as the first entry
        &FAI::execute_ro_command("readlink -f /dev/$device/$l", \@fstab_key, 0);
        
        # remove the newline
        chomp ($fstab_key[0]);

        # make sure we got back a real device
        ($FAI::no_dry_run == 0 || -b $fstab_key[0]) 
          or die "Failed to resolve /dev/$device/$l\n";
        
        my $device_name = "/dev/$device/$l";
        if ($l_ref->{encrypt}) {
          # encryption requested, rewrite the device name
          $device_name =~ "s#/#_#g";
          $device_name = "/dev/mapper/crypt$device_name";
        } else {
          $device_name = $fstab_key[0];
        }
        
        # according to http://grub.enbug.org/LVMandRAID, this should work...
        # if the mount point is / or /boot, the variables should be set, unless
        # they are already
        if ($l_ref->{mountpoint} eq "/boot" || ($l_ref->{mountpoint} eq "/" && 
              !defined ($FAI::disk_var{BOOT_PARTITION}))) {
          # set the BOOT_DEVICE and BOOT_PARTITION variables, if necessary
          $FAI::disk_var{BOOT_PARTITION} = $device_name;
          defined ($FAI::disk_var{BOOT_DEVICE}) or
            $FAI::disk_var{BOOT_DEVICE} = $device_name;
        }

        push @fstab, &FAI::create_fstab_line($l_ref, $device_name, $device_name);
      }
    } elsif ($c eq "RAID") {

      # create a line in the output file for each device
      foreach my $r (keys %{ $config->{$c}->{volumes} }) {

        # keep a reference to save some typing
        my $r_ref = $config->{$c}->{volumes}->{$r};

        # skip entries without a mountpoint
        next if ($r_ref->{mountpoint} eq "-");
        
        my $device_name = "/dev/md$r";
        if ($r_ref->{encrypt}) {
          # encryption requested, rewrite the device name
          $device_name =~ "s#/#_#g";
          $device_name = "/dev/mapper/crypt$device_name";
        } 

        # according to http://grub.enbug.org/LVMandRAID, this should work...
        # if the mount point is / or /boot, the variables should be set, unless
        # they are already
        if ($r_ref->{mountpoint} eq "/boot" || ($r_ref->{mountpoint} eq "/" && 
              !defined ($FAI::disk_var{BOOT_PARTITION}))) {
          # set the BOOT_DEVICE and BOOT_PARTITION variables, if necessary
          $FAI::disk_var{BOOT_PARTITION} = "$device_name";
          defined ($FAI::disk_var{BOOT_DEVICE}) or
            $FAI::disk_var{BOOT_DEVICE} = "$device_name";
        }

        push @fstab, &FAI::create_fstab_line($r_ref, $device_name, $device_name);
      }
    } else {
      &FAI::internal_error("Unexpected key $c");
    }
  }

  # cleanup the swaplist (remove leading space and add quotes)
  $FAI::disk_var{SWAPLIST} =~ s/^\s*/"/;
  $FAI::disk_var{SWAPLIST} =~ s/\s*$/"/;

  # sort the lines in @fstab to enable all sub mounts
  @fstab = sort { [split("\t",$a)]->[1] cmp [split("\t",$b)]->[1] } @fstab;

  # add a nice header to fstab
  unshift @fstab,
    "# <file sys>\t<mount point>\t<type>\t<options>\t<dump>\t<pass>";
  unshift @fstab, "#";
  unshift @fstab, "# /etc/fstab: static file system information.";

  # return the list of lines
  return @fstab;
}

1;

