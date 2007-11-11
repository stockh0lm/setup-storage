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
# @file commands.pm
#
# @brief Build the required commands using the config stored in %FAI::configs
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
# @brief Build the mkfs commands for the partition pointed to by $partition
#
# @param $device Device name of the target partition
# @param $partition Reference to partition in the config hash
#
# The command is added @FAI::commands
#
################################################################################
sub build_mkfs_commands {
  my ( $device, $partition ) = @_;

  defined( $partition->{filesystem} )
    or die "INTERNAL ERROR: filesystem is undefined\n";
  my $fs = $partition->{filesystem};

  return if ( $fs eq "-" );

  my ($create_options) = $partition->{fs_options}=~m/.*createopts="([^"]+)".*/;
  my ($tune_options) = $partition->{fs_options}=~m/.*tuneopts="([^"]+)".*/;
  $create_options = $partition->{fs_options} unless $create_options;
  print STDERR "create_options: $create_options tune_options: $tune_options\n" if $FAI::debug;

  # create the file system with options
  my $create_tool = "mkfs.$fs";
  ( $fs eq "swap" ) and $create_tool = "mkswap";
  push @FAI::commands, "$create_tool $create_options $device";
  
  # possibly tune the file system
  return unless $tune_options;
  my $tune_tool;
  ( $fs eq "ext2" ) and $tune_tool = "tune2fs";
  ( $fs eq "ext3" ) and $tune_tool = "tune2fs";
  ( $fs eq "reiserfs" ) and $tune_tool = "reiserfstune";
  die "Don't know how to tune $fs\n" unless $tune_tool;
  push @FAI::commands, "$tune_tool $tune_options $device";
}

################################################################################
#
# @brief Using the configurations from %FAI::configs, a list of commands is
# built to create any RAID devices
#
# The list is @FAI::commands
#
################################################################################
sub build_raid_commands {
  # TODO: do we need to stop anything before we continue? Do we need to issue
  # mdadm --misc --zero-superblock /dev/hdx?

  # loop through all configs
  foreach my $config ( keys %FAI::configs ) {

    # no LVM here
    next if ( $config =~ /^VG_(.+)$/ );

    # no physical devices here
    next if ( $config =~ /^PHY_(.+)$/ );

    # create the RAID devices and the filesystems
    ( $config eq "RAID" ) or die "INTERNAL ERROR: Invalid config\n";

    # create all raid devices
    foreach my $id ( sort keys %{ $FAI::configs{$config}{volumes} } ) {

      # keep a reference to the current volume
      my $vol_ref = ( \%FAI::configs )->{$config}->{volumes}->{$id};
      # the desired RAID level
      my $level = $vol_ref->{mode};

      # prepend "raid", if the mode is numeric-only
      $level = "raid" . $level if ( $level =~ /^\d+$/ );

      # the list of RAID devices
      my @devs = keys %{ $vol_ref->{devices} };

      # set proper partition types for RAID
      foreach my $d (@devs) {
        # skip devices marked missing
        next if( 1 == $vol_ref->{devices}{$d}{missing} );
        # only match physical partitions (this string of matchings is hopefully complete)
        next unless( $d =~
          m{^/dev/(cciss/c\dd\dp|ida/c\dd\dp|rd/c\dd\dp|ataraid/d\dp|sd[a-t]|hd[a-t])(\d+)$} );
        my $disk = "/dev/$1";
        my $part_no = $2;
        # in case the name was /dev/cciss/c0d1p or the like, remove the trailing
        # p to get the disk name
        $disk =~ s/(\d)p$/$1/;
        # make sure this device really exists (we can't check for the partition
        # as that may be created later on
        ( -b $disk ) or die "Specified disk $disk does not exist in this system!\n";
        # set the raid flag
        push @FAI::commands, "parted -s $disk set $part_no raid on";
      }
      # wait for udev to set up all devices
      push @FAI::commands, "udevsettle --timeout=10";
      
      # create the command
      push @FAI::commands,
        "yes | mdadm --create /dev/md$id --level=$level "
        . "--raid-devices="
        . scalar(@devs) . " "
        . join( " ", @devs );

      # create the filesystem on the volume
      &FAI::build_mkfs_commands( "/dev/md$id",
        \%{ $FAI::configs{$config}{volumes}{$id} } );
    }
  }
}

################################################################################
#
# @brief Erase the LVM signature from a list of devices that should be prestine
# in order to avoid confusion of the lvm tools
#
# The list is @FAI::commands
#
################################################################################
sub erase_lvm_signature {
    my( $devices_aref ) = @_;
      # first remove the dm_mod module to prevent ghost lvm volumes 
      # from existing
#      push @FAI::commands, "modprobe -r dm_mod";
      # zero out (broken?) lvm signatures
#      push @FAI::commands, "dd if=/dev/zero of=$_ bs=1 count=1"
#        foreach ( @{$devices_aref} );
    my $device_list = join(" ", (@{$devices_aref}) );
    ( $FAI::debug > 0 ) and print "list of erased devices: $device_list\n"; 
    push @FAI::commands, "pvremove -ff -y $device_list";

      # reload module
#      push @FAI::commands, "modprobe dm_mod";

}

################################################################################
#
# @brief Using the configurations from %FAI::configs, a list of commands is
# built to setup the LVM
#
# The list is @FAI::commands
#
################################################################################
sub build_lvm_commands {
  # loop through all configs
  foreach my $config ( keys %FAI::configs ) {
    # no physical devices here
    next if ( $config =~ /^PHY_(.+)$/ );

    # no RAID devices here
    next if ( $config eq "RAID" );

    # create the volume groups, the logical volumes and the filesystems
    ( $config =~ /^VG_(.+)$/ ) or die "INTERNAL ERROR: Invalid config\n";

    # the volume group
    my $vg = $1;

    # find volumes that should be preserved or resized and ensure that they
    # already exist
    foreach my $lv ( keys %{ $FAI::configs{$config}{volumes} } ) {
      # reference to the size of the current logical volume
      my $lv_ref_size = ( \%FAI::configs )->{$config}->{volumes}->{$lv}->{size};
      next unless ( $lv_ref_size->{preserve} == 1 || $lv_ref_size->{resize} == 1 );

      # preserved or resized volumes must exist already
      defined( $FAI::current_lvm_config{$vg}{volumes}{$lv} )
        or die "/dev/$vg/$lv can't be preserved, it does not exist.\n";
    }

    # set proper partition types for LVM
    foreach my $d (keys %{ $FAI::configs{$config}{devices} }) {
      # only match physical partitions (this string of matchings is hopefully complete)
      next unless( $d =~
        m{^/dev/(cciss/c\dd\dp|ida/c\dd\dp|rd/c\dd\dp|ataraid/d\dp|sd[a-t]|hd[a-t])(\d+)$} );
      my $disk = "/dev/$1";
      my $part_no = $2;
      # in case the name was /dev/cciss/c0d1p or the like, remove the trailing
      # p to get the disk name
      $disk =~ s/(\d)p$/$1/;
      # make sure this device really exists (we can't check for the partition
      # as that may be created later on
      ( -b $disk ) or die "Specified disk $disk does not exist in this system!\n";
      # set the lvm flag
      push @FAI::commands, "parted -s $disk set $part_no lvm on";
    }
    # wait for udev to set up all devices
    push @FAI::commands, "udevsettle --timeout=10";

    # create the volume group, if it doesn't exist already
    if ( !defined( $FAI::current_lvm_config{$vg} ) ) {
      # create all the devices
      my @devices = keys %{ $FAI::configs{$config}{devices} };
      &FAI::erase_lvm_signature(\@devices);
      push @FAI::commands, "pvcreate $_" foreach ( @devices );
      # create the volume group
      push @FAI::commands, "vgcreate $vg "
        . join( " ", keys %{ $FAI::configs{$config}{devices} } );
    }

    # otherwise add or remove the devices for the volume group, run pvcreate
    # where needed (using pvdisplay <bla> || pvcreate <bla>)
    else {

      # the list of devices to be created
      my %new_devs = ();

      # create an undefined entry for each new device
      @new_devs{ keys %{ $FAI::configs{$config}{devices} } } = ();
      
      my @new_devices = keys %new_devs;
      
      &FAI::erase_lvm_signature( \@new_devices );
      
      # create all the devices
      push @FAI::commands, "pvcreate $_" foreach ( @new_devices );

      # extend the volume group by the new devices (includes the current ones)
      push @FAI::commands, "vgextend $vg " . join( " ", keys %new_devs );

      # the devices to be removed
      my %rm_devs = ();
      @rm_devs{ @{ $FAI::current_lvm_config{$vg}{"physical_volumes"} } } = ();

      # remove remaining devices from the list
      delete $rm_devs{$_} foreach ( keys %new_devs );

      # run vgreduce to get them removed
      push @FAI::commands, "vgreduce $vg " . join( " ", keys %rm_devs )
        if ( scalar( keys %rm_devs ) );
    }

    # enable the volume group
    push @FAI::commands, "vgchange -a y $vg";

    # remove, resize, create the logical volumes
    # remove all volumes that do not exist anymore or need not be preserved
    foreach my $lv ( keys %{ $FAI::current_lvm_config{$vg}{volumes} } ) {
      # skip preserved/resized volumes
      next if ( defined( $FAI::configs{$config}{volumes}{$lv} )
        && ( $FAI::configs{$config}{volumes}{$lv}{size}{preserve} == 1
          || $FAI::configs{$config}{volumes}{$lv}{size}{resize} ));

      # remove $lv
      push @FAI::commands, "lvremove -f $vg/$lv";
    }

    # now create or resize the configured logical volumes
    foreach my $lv ( keys %{ $FAI::configs{$config}{volumes} } ) {
      # reference to the size of the current logical volume
      my $lv_ref_size = ( \%FAI::configs )->{$config}->{volumes}->{$lv}->{size};
      # skip preserved partitions, but ensure that they exist
      if ( $lv_ref_size->{preserve} == 1 ) {
        defined( $FAI::current_lvm_config{$vg}{volumes}{$lv} )
          or die "Preserved volume $vg/$lv does not exist\n";
        next;
      }

      # resize the volume
      if ( $lv_ref_size->{resize} == 1 ) {
        defined( $FAI::current_lvm_config{$vg}{volumes}{$lv} )
          or die "Resized volume $vg/$lv does not exist\n";

        # note that resizing a volume destroys the data on it
        push @FAI::commands,
          "lvresize -L " . $lv_ref_size->{eff_size} . " $vg/$lv";
      }

      # create a new volume
      else {
        push @FAI::commands,
          "lvcreate -n $lv -L " . $lv_ref_size->{eff_size} . " $vg";

        # create the filesystem on the volume
        &FAI::build_mkfs_commands( "/dev/$vg/$lv",
          \%{ $FAI::configs{$config}{volumes}{$lv} } );
      }
    }

  }
}

################################################################################
#
# @brief Using the configurations from %FAI::configs, a list of commands is
# built to setup the partitions
#
# The list is @FAI::commands
#
################################################################################
sub build_disk_commands {
  # loop through all configs
  foreach my $config ( keys %FAI::configs ) {
    # no RAID devices here
    next if ( $config eq "RAID" );

    # no LVM here
    next if ( $config =~ /^VG_(.+)$/ );

    # configure a physical device
    ( $config =~ /^PHY_(.+)$/ ) or die "INTERNAL ERROR: Invalid config\n";

    # the device to be configured
    my $disk = $1;

    # create partitions on non-virtual configs
    if ( $FAI::configs{$config}{virtual} == 0 ) {
      # the list of partitions that must be preserved
      my @to_preserve = ();

      # find partitions that should be preserved or resized
      foreach my $part_id ( sort keys %{ $FAI::configs{$config}{partitions} } ) {
        # reference to the current partition
        my $part_ref = ( \%FAI::configs )->{$config}->{partitions}->{$part_id};
        next unless (
          $part_ref->{size}->{preserve} == 1 || $part_ref->{size}->{resize} == 1 );

        # preserved or resized partitions must exist already
        defined( $FAI::current_config{$disk}{partitions}{$part_id} )
          or die "$part_id can't be preserved, it does not exist.\n";

        # add a mapping from the configured partition to the existing one
        # (identical here, may change for extended partitions below)
        $part_ref->{maps_to_existing} = $part_id;

        # add $part_id to the list of preserved partitions
        push @to_preserve, $part_id;

      }

      # sort the list of preserved partitions
      @to_preserve = sort { $a <=> $b } @to_preserve;

      # add the extended partition as well, if logical partitions must be
      # preserved; and mark it as resize
      if ( $FAI::configs{$config}{disklabel} eq "msdos" ) {
        # we assume there are no logical partitions
        my $has_logical = 0;
        my $extended    = -1;

        # now check all entries; the array is sorted
        foreach my $part_id (@to_preserve) {
          # the extended partition may already be listed; then, the id of the
          # extended partition must not change
          if ( $FAI::current_config{$disk}{partitions}{$part_id}{is_extended} == 1 ) {
            ( defined( $FAI::configs{$config}{partitions}{$extended}{size}{extended})
                && defined( $FAI::current_config{$disk}{partitions}{$extended}{is_extended})
                && $FAI::configs{$config}{partitions}{$extended}{size}{extended} == 1
                && $FAI::current_config{$disk}{partitions}{$extended}{is_extended} == 1 ) 
                or die "ID of extended partition changes\n";

            # make sure resize is set
            $FAI::configs{$config}{partitions}{$part_id}{size}{resize} = 1;
            $extended = $part_id;
            last;
          }

          # there is some logical partition
          if ( $part_id > 4 ) {
            $has_logical = 1;
            last;
          }
        }

        # if the extended partition is not listed yet, find and add it now; note
        # that we need to add the existing one
        if ( 1 == $has_logical && -1 == $extended ) {
          foreach my $part_id ( sort keys %{ $FAI::current_config{$disk}{partitions} } ) {

            # no extended partition
            next unless ( $FAI::current_config{$disk}{partitions}{$part_id}{is_extended} == 1 );

            # find the configured extended partition to set the mapping
            foreach my $p ( sort keys %{ $FAI::configs{$config}{partitions} } ) {
              # reference to the current partition
              my $part_ref = ( \%FAI::configs )->{$config}->{partitions}->{$p};
              next unless ( $part_ref->{size}->{extended} == 1 );

              # make sure resize is set
              $part_ref->{size}->{resize} = 1;

              # store the id for further checks
              $extended = $p;

              # add a mapping entry to the existing extended partition
              $part_ref->{maps_to_existing} = $part_id;

              # add it to the preserved partitions
              push @to_preserve, $p;

              last;
            }

            # sort the list of preserved partitions (again)
            @to_preserve = sort { $a <=> $b } @to_preserve;

            last;
          }
        }

        # a sanity check: if there are logical partitions, they extended must
        # have been added
        ( 0 == $has_logical || -1 != $extended ) or die
          "INTERNAL ERROR: Required extended partition not detected for preserve\n";
      }

      # A new disk label may only be written if no partitions need to be
      # preserved
      ( ( $FAI::configs{$config}{disklabel} eq
            $FAI::current_config{$disk}{disklabel})
          || ( scalar(@to_preserve) == 0 ) ) 
          or die "Can't change disklabel, partitions are to be preserved\n";

      # write the disklabel to drop the previous partition table
      push @FAI::commands, "parted -s $disk mklabel "
        . $FAI::configs{$config}{disklabel};

      # once we rebuild partitions, their ids are likely to change; this counter
      # helps keeping track of this
      my $part_nr = 0;

      # now rebuild all preserved partitions
      foreach my $part_id (@to_preserve) {
        # get the existing id
        my $mapped_id =
          $FAI::configs{$config}{partitions}{$part_id}{maps_to_existing};

        # get the original starts and ends
        my $start =
          $FAI::current_config{$disk}{partitions}{$mapped_id}{begin_byte};
        my $end =
          $FAI::current_config{$disk}{partitions}{$mapped_id}{end_byte};

        # the type of the partition defaults to primary
        my $part_type = "primary";
        if ( $FAI::configs{$config}{disklabel} eq "msdos" ) {

          # change the partition type to extended or logical as appropriate
          if ( $FAI::configs{$config}{partitions}{$part_id}{size}{extended} == 1 ) {
            $part_type = "extended";
          } elsif ( $part_id > 4 ) {
            $part_type = "logical";
            $part_nr = 4 if ( $part_nr < 4 );
          }
        }

        # increase the partition counter for the partition created next and
        # write it to the configuration
        $part_nr++;
        $FAI::current_config{$disk}{partitions}{$mapped_id}{new_id} = $part_nr;

        # build a parted command to create the partition
        push @FAI::commands,
          "parted -s $disk mkpart $part_type ${start}B ${end}B";
      }

      # resize partitions; first we shrink partitions, then grow others;
      # furthermore we start from the end to shrink logical partitions before
      # the extended one, but grow partitions starting from the beginning
      my @shrink_list = reverse sort (@to_preserve);
      my @grow_list   = ();

      # iterate over the worklists
      foreach my $part_id (@shrink_list) {
        # reference to the current partition
        my $part_ref = ( \%FAI::configs )->{$config}->{partitions}->{$part_id};
        # anything to be done?
        next unless ( $part_ref->{size}->{resize} == 1 );

        # get the existing id
        my $mapped_id = $part_ref->{maps_to_existing};

        # if partition is to be grown, move it to then grow_list
        if ( $part_ref->{size}->{eff_size} >
          $FAI::current_config{$disk}{partitions}{$mapped_id}{count_byte} ) {
          unshift @grow_list, $part_id;
          next;
        }

        # get the new partition id
        my $p = $FAI::current_config{$disk}{partitions}{$mapped_id}{new_id};

        # get the new starts and ends
        my $start = $part_ref->{start_byte};
        my $end = $part_ref->{end_byte};

        # build an appropriate command
        push @FAI::commands, "parted -s $disk resize $p ${start}B ${end}B";
      }

      # grow the remaining partitions
      foreach my $part_id (@grow_list) {
        # reference to the current partition
        my $part_ref = ( \%FAI::configs )->{$config}->{partitions}->{$part_id};

        # get the existing id
        my $mapped_id = $part_ref->{maps_to_existing};

        # get the new partition id
        my $p = $FAI::current_config{$disk}{partitions}{$mapped_id}{new_id};

        # get the new starts and ends
        my $start = $part_ref->{start_byte};
        my $end = $part_ref->{end_byte};

        # build an appropriate command
        push @FAI::commands, "parted -s $disk resize $p ${start}B ${end}B";
      }

      # write the disklabel again to drop the partition table
      push @FAI::commands, "parted -s $disk mklabel " . $FAI::configs{$config}{disklabel};

      # generate the commands for creating all partitions
      foreach my $part_id ( sort keys %{ $FAI::configs{$config}{partitions} } ) {
        # reference to the current partition
        my $part_ref = ( \%FAI::configs )->{$config}->{partitions}->{$part_id};

        # get the new starts and ends
        my $start = $part_ref->{start_byte};
        my $end = $part_ref->{end_byte};

        # the type of the partition defaults to primary
        my $part_type = "primary";
        if ( $FAI::configs{$config}{disklabel} eq "msdos" ) {

          # change the partition type to extended or logical as appropriate
          if ( $part_ref->{size}->{extended} == 1 ) {
            $part_type = "extended";
          } elsif ( $part_id > 4 ) {
            $part_type = "logical";
          }
        }

        # build a parted command to create the partition
        push @FAI::commands, "parted -s $disk mkpart $part_type ${start}B ${end}B";
      }

      # set the bootable flag, if requested at all
      push @FAI::commands,
        "parted -s $disk set "
        . $FAI::configs{$config}{bootable}
        . " boot on"
        if ( $FAI::configs{$config}{bootable} > -1 );

      # wait for udev to set up all devices
      push @FAI::commands, "udevsettle --timeout=10";
    }

    # generate the commands for creating all filesystems
    foreach my $part_id ( sort keys %{ $FAI::configs{$config}{partitions} } ) {
      # reference to the current partition
      my $part_ref = ( \%FAI::configs )->{$config}->{partitions}->{$part_id};

      # skip preserved/resized/extended partitions
      next if ( $part_ref->{size}->{preserve} == 1
        || $part_ref->{size}->{resize} == 1 || $part_ref->{size}->{extended} == 1 );

      # create the filesystem on $disk$part_id
      &FAI::build_mkfs_commands( $disk . $part_id, $part_ref );
    }
  }
}

################################################################################
#
# @brief Whatever happened, write the previous partition table to the disk again
#
################################################################################
sub restore_partition_table {

  # loop through all existing configs
  foreach my $disk ( keys %FAI::current_config ) {

    # write the disklabel again to drop the partition table
    &FAI::execute_command( "parted -s $disk mklabel "
        . $FAI::current_config{$disk}{disklabel} );

    # generate the commands for creating all partitions
    foreach my $part_id ( sort keys %{ $FAI::current_config{$disk}{partitions} } ) {
      # reference to the current partition
      my $curr_part_ref = ( \%FAI::current_config )->{$disk}->{partitions}->{$part_id};

      # get the starts and ends
      my $start = $curr_part_ref->{begin_byte};
      my $end = $curr_part_ref->{end_byte};

      # the type of the partition defaults to primary
      my $part_type = "primary";
      if ( $FAI::current_config{$disk}{disklabel} eq "msdos" ) {

        # change the partition type to extended or logical as appropriate
        if ( $curr_part_ref->{is_extended} == 1 ) {
          $part_type = "extended";
        } elsif ( $part_id > 4 ) {
          $part_type = "logical";
        }
      }

      # build a parted command to create the partition
      &FAI::execute_command( "parted -s $disk mkpart $part_type ${start}B ${end}B" );
    }
    warn "Partition table of disk $disk has been restored\n";
  }

  die "Storage Magic failed, but the partition tables have been restored\n";
}

1;

