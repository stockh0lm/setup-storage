package FAI::Updater;
# 
#     FAI::Updater.pm -- The main class starting and supervizing the updates
#                        Also an abstract display class is defined here, from
#                        which the real display modules should be derived
#     
#     fai-updater - start and supervise fai softupdates on many hosts
#     Copyright (C) 2004-2006  Henning Glawe <glaweh@debian.org>
# 
#     This program is free software; you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation; either version 2 of the License, or
#     (at your option) any later version.
# 
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
# 
#     You should have received a copy of the GNU General Public License
#     along with this program; if not, write to the Free Software
#     Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
# 
# 
use strict;
use warnings;
use POSIX qw(:sys_wait_h);
use IPC::Open2;
our @states = qw(unreachable error unfinished empty success running started waiting);
#   unreachable - host didn't ping
#   error       - an error occured, hav a look at the logfiles
#   unfinished  - update didn't run to the end (?)
#   empty       - logfile is empty
#   success     - updated without errors
#   running     - update is running
#   started     - update has been started
#   waiting     - update not yet started

sub new {
  my $class = shift;
  my $self = {};
  bless($self,$class);
  $self->_init(@_);
  return $self;
}

sub _init {
  my $self=shift;
  $self->{HOSTPID}={};
  $self->{DRYRUN}=0;
  $self->{TO_DO}=();
  $self->{MAX_SIMULTANOUS}=4;
  $self->{PING}=1;
  $self->{ORDERED}=0;
  my %dummy=(@_);
  map { $self->{$_}=$dummy{$_} }keys %dummy;
  die "I need a DISPLAY" unless $self->{DISPLAY};
  die "I need a LOGDIR" unless $self->{LOGDIR};
  die "logdir ".$self->{LOGDIR}." doesn't exist !" unless -d $self->{LOGDIR};
  $self->{COMMAND} = ($self->{DRYRUN} ? "libexec/dryrun" : "libexec/faiupdate" );
}

sub _start_one {
  my ($self,$host)=(shift,shift);
  
  if ($self->{PING}) {
    # try to ping the machine before update
    if (my $pid=fork) {
      waitpid($pid,0);
      my $returncode=($? >> 8);
      if ($returncode != 0) {
        # host is unreachable if fping doesn't return 0
        $self->{DISPLAY}->set_state($host,'unreachable');
        return;
      }
    } else {
      die "cannot fork: $!" unless defined $pid;
      #don't clutter the ouput
      open STDIN,'/dev/null'; open STDERR,'>/dev/null'; open STDOUT,'>/dev/null';
      exec '/usr/bin/fping','-q',$host;
    }
  }
  
  if (my $pid=fork) {
    $self->{HOSTPID}->{$host} = $pid;
  } else {
    die "cannot fork: $!" unless defined $pid;
    open STDIN,'/dev/null'; open STDERR,'>/dev/null';
    open STDOUT,">".$self->{LOGDIR}."/$host";
    exec $self->{COMMAND},$host;
  } 
}

# extract state from a complete logfile
sub _check_logfile {
  my ($self,$host) = (shift,shift);
  my $logfile=$self->{LOGDIR} . "/$host";
  open LOGFILE,$logfile;
  my $state=(exists $self->{HOSTPID}->{$host} ? 'started' : 'empty');
  while (<LOGFILE>) {
    if (/Fully Automatic Installation/) {
      $state=(exists $self->{HOSTPID}->{$host} ? 'running' : 'unfinished');
    }
    if (/An error occured/) {
      $state='error';
      last;
    }
    if (/Sav\S+ log files/) {
      $state='success';
    }
  }
  close LOGFILE;
  return $state;
}

sub init_hostlist {
  my $self=shift;
  my @hostlist;

  if ($self->{ORDERED}) {
    @{$self->{TO_DO}}=@_;
  } else {
    my %weight;
    map { $weight{$_}=rand; } @_;
    @{$self->{TO_DO}}=sort { $weight{$a} <=> $weight{$b} } @_;
  }
  # set state to waiting for all 
  map { $self->{DISPLAY}->set_state($_,'waiting') } @{$self->{TO_DO}};
}

sub run {
  my $self=shift;
  my $running=0;
  foreach my $name (keys %{$self->{HOSTPID}}) {
    if ( waitpid($self->{HOSTPID}->{$name},WNOHANG)==0 ) {
      $running++;
    } else {
      delete $self->{HOSTPID}->{$name};
    } 
    $self->{DISPLAY}->set_state($name,$self->_check_logfile($name));
  }
  
  # fork new processes if there are less running than possible
  while ($running<$self->{MAX_SIMULTANOUS}) {
    last unless my $host=shift @{$self->{TO_DO}};
    $self->_start_one($host);
    $running++;
  }
  return $running;
}

sub max_simultanous {
  my $self = shift;
  my $neu = shift;
  if (defined $neu) {
  	$self->{MAX_SIMULTANOUS}=$neu;
  }
  return $self->{MAX_SIMULTANOUS};
}

package FAI::Updater::Display;
use strict;
# constructor
sub new {
  my $class = shift;
  my $self = {};
  bless($self,$class);
  $self->_init(@_);
  return($self);
}

sub _init {
  my $self=shift;
  $self->{STATE}={};
  $self->{NEXT}=undef;
  my %dummy=(@_);
  map { $self->{$_}=$dummy{$_} } keys %dummy;
}

sub set_state {
  my $self=shift;
  $self->{NEXT}->set_state(@_) if defined $self->{NEXT};
  my ($host,$state)=(shift,shift);
  $self->{STATE}->{$host}=$state;
}

sub append {
  my $self=shift;
  $self->{NEXT}->append(@_) if defined $self->{NEXT};
  $self->{NEXT}=shift;
}
1; # so the require or use succeeds
