package FAI::Updater::Display::Curses;
#
#     FAI::Updater::Display::Curses -- Display class using Curses::UI
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
use Curses;
use Curses::UI;
use Curses::UI::Common;
use FAI::Updater;
use base qw(FAI::Updater::Display);
	
sub _init {
	my $self=shift;
	$self->{TITLES}=[qw(unreachable error success running waiting)];
	$self->{COLORS}={ unreachable=>'magenta',
		error=>'red',
		success=>'green',
		running=>'yellow',
		waiting=>'blue'};
	$self->{COLUMN}={
		unreachable=>0,
		error=>1,
		unfinished=>1,
		empty=>0,
		success=>2,
		running=>3,
		started=>3,
		waiting=>4
	};
	$self->SUPER::_init(@_);
	die "I need a WIN" unless $self->{WIN};
	my $hostwidth=POSIX::floor($self->{WIN}->width()/scalar(@{$self->{TITLES}}));
	$self->{WIN}->{-width}=$hostwidth*scalar(@{$self->{TITLES}});
	$self->{WIN}->layout();
	my $sofar=0;
	my $idx=0;
	$self->{COL}=[];
	foreach (@{$self->{TITLES}}) {
		$self->{COL}->[$idx]=$self->{WIN}->add($_,'MyListbox',
			-width=>$hostwidth,
			-x=>$sofar,
			-border=>1,
			-title=>$_,
			-bg=>$self->{COLORS}->{$_},
			-vscrollbar=>1
			);
		$self->{COL}->[$idx]->onChange($self->{SELECT}) if ($self->{SELECT});
		# change default bindings
		$self->{COL}->[$idx]->clear_binding('option-select');
		$self->{COL}->[$idx]->clear_binding('loose-focus');
		$self->{COL}->[$idx]->set_binding('option-select',KEY_ENTER,KEY_SPACE);
		$self->{COL}->[$idx]->set_binding('loose-focus',KEY_RIGHT,CUI_TAB,KEY_BTAB);
		$self->{COL}->[$idx]->set_binding('focus-prev',KEY_LEFT);

		$idx++;$sofar+=$hostwidth;
	}
}

sub set_state {
	my $self=shift;
	my ($host,$state)=(shift,shift);
	my $oldcol=(exists $self->{STATE}->{$host} ? 
		$self->{COLUMN}->{$self->{STATE}->{$host}} :
		-1);
	$self->SUPER::set_state($host,$state);
	my $newcol=$self->{COLUMN}->{$state};
	if ($oldcol!=$newcol) {
		$self->{COL}->[$oldcol]->remove($host) unless ($oldcol<0);
		$self->{COL}->[$newcol]->append($host);
	}
}

1;
