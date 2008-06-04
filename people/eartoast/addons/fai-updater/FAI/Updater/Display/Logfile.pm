package FAI::Updater::Display::Logfile;
# 
#     FAI::Updater::Display::Logfile -- Display class writing the state 
#                                       transitions to a logfile
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
use FAI::Updater;
use POSIX qw(strftime);
use base qw(FAI::Updater::Display);

sub _init {
  my $self=shift;
  $self->SUPER::_init(@_);
  die "I need a FILENAME" unless $self->{FILENAME};
  open $self->{FH},">".$self->{FILENAME};
  $self->{FH}->autoflush() if $self->{AUTOFLUSH};
}

sub DESTROY {
  my $self=shift;
  close $self->{FH};
}

sub set_state {
  my ($self,$host,$state)=(shift,shift,shift);
  my $oldstate=$self->{STATE}->{$host} || 'none';
  $self->SUPER::set_state($host,$state);
  unless ($state eq $oldstate) {
    print {$self->{FH}} "".strftime("%H:%M:%S",localtime)." $host $oldstate -> $state\n";
  }
}

1;
