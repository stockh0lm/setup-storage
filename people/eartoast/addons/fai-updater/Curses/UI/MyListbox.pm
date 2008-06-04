package Curses::UI::MyListbox;
# 
#     MyListBox.pm -- a Curses::UI::Listbox with the capability to add and 
#                     remove elements at runtime
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
use base qw(Curses::UI::Listbox);

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->set_routine('focus-prev',\&focus_prev);
}

sub focus_prev {
	my $self = shift;
	$self->loose_focus(KEY_BTAB);
}

sub append {
	my $self = shift;
	my $value = shift;
	push @{$self->{-values}},$value;
	$self->draw();
}

sub remove {
	my $self = shift;
	my $value = shift;
	foreach (0 .. @{$self->{-values}}) {
 		if (defined $self->{-values}[$_] and $self->{-values}[$_] eq $value) {
			splice(@{$self->{-values}},$_,1);
			$self->{-ypos}-- if ($_<$self->{-ypos});
			$self->{-selected}-- if (defined $self->{-selected} and ($_<$self->{-selected}));
		}
	}
	$self->draw();
}

return 1;
