#! /usr/bin/perl

# define classes for different disk configurations

# global variables:
# $numdisks             # number of disks
# %disksize{$device}    # size for each device in Mb
# $sum_disk_size        # sum of all disksizes in Mb

require Debian::Fai;

read_disk_info();

# rules for classes
#-------------------------------------------------------
# two SCSI disks 2-5 GB
($numdisks == 2) and
    disksize(sda,2000,5000) and
    disksize(sdb,2000,5000) and
    class("SD_2_5GB");

# one disk 1-4 GB, IDE or SCSI
($numdisks == 1) and
    testsize($sum_disk_size,1000,4000) and
    class("4GB");

#-------------------------------------------------------
# do not edit beyond this line

exit;
