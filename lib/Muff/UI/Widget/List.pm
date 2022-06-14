package Muff::UI::Widget::List;

use strict;
use warnings FATAL => qw(all);

use Carp;
use Curses;
use POSIX;

use Muff::Struct qw(struct);

use parent 'Muff::UI::Widget::Common';

sub new {
	my ($class, $args) = @_;

	$args->{on}->{list_setline} = \&setline
		if ! $args->{on} || ! $args->{on}->{list_setline};

	my $self = $class->SUPER::new($args);

	$self->{widget} = struct {
		field    => $args->{field},
		content  => $args->{content} || [],
		index    => $args->{index} || 0,
		selectable => (exists $args->{selectable} ? $args->{selectable} : 1),
		selected => undef,
	};

	my $me = bless($self, $class);

	$me->call_hook('list_create');
	return $me;
}

sub index {
	my $self = shift;
	$self->{widget}->{index};
}

sub get_text {
	my $self = shift;
	my $i = shift;

	my $text;

	if ($self->{widget}->{field}) {
		$text = $self->{widget}->{content}->[$i]->{$self->{widget}->{field}};
	} else {
		$text = $self->{widget}->{content}->[$i];
	}

	if (length($text) >= $self->{width}) {
		return substr($text, 0, $self->{width});
	}
	return $text . (" " x ($self->{width} - length($text)));
}

sub setline {
	my ($self, $i, $selected, $text) = @_;

	if ($self->{widget}->{selectable} && $selected) {
		$self->{bin}->attron(A_BOLD | A_REVERSE);
	}

	$self->{bin}->addstring($i, 0, $text);

	if ($self->{widget}->{selectable} && $selected) {
		$self->{bin}->attroff(A_BOLD | A_REVERSE);
	}
}

sub fill {
	my $self = shift;

	$self->{widget}->{index} = @{$self->{widget}->{content}}
		if $self->{widget}->{index} > @{$self->{widget}->{content}};

	my $page = floor($self->{widget}->{index} / $self->{height});
	my $start = $self->{height} * $page;

	$self->{widget}->{selected} = $self->{widget}->{index} - $start;

	for (my $i = 0; $i < $self->{height}; $i++) {
		if (($start + $i) == @{$self->{widget}->{content}}) {
			$self->{bin}->clrtobot();
			last;
		}

		$self->call_hook('list_setline', $i, ($i == $self->{widget}->{selected}), $self->get_text($start + $i));
	}

	$self->{bin}->move($self->{widget}->{selected}, 0);
	$self->{bin}->refresh();
}

sub draw {
	my $self = shift;

	my $cpair = $self->{colors}->pair($self->{color_fg}, $self->{color_bg});

	croak("win object leak")
		if $self->{bin};

	$self->{bin} = newwin($self->{height}, $self->{width}, $self->{y}, $self->{x});
	$self->{bin}->bkgd($cpair);

	$self->fill();

	return $self->SUPER::draw;
}

sub select {
	my $self = shift;
	my $offset = ($_[0] > 0 ? 1 : -1);

	$self->call_hook('list_setline', $self->{widget}->{selected}, 0, $self->get_text($self->{widget}->{index}));

	if (($self->{widget}->{index} + $offset) < @{$self->{widget}->{content}}) {
		$self->{widget}->{index} += $offset;

		if (($self->{widget}->{selected} + $offset) < 0) {
			if ($self->{widget}->{index} >= 0) {
				$self->{bin}->move(0, 0);
				$self->{bin}->insertln();
			} else {
				$self->{widget}->{index} = 0;
			}

		} elsif (($self->{widget}->{selected} + $offset) == $self->{height}) {
			$self->{bin}->move(0, 0);
			$self->{bin}->deleteln();
		} else {
			$self->{widget}->{selected} += $offset;
		}
	}

	$self->call_hook('list_setline', $self->{widget}->{selected}, 1, $self->get_text($self->{widget}->{index}));

	$self->{bin}->move($self->{widget}->{selected}, 0);
	$self->{bin}->refresh();
}

sub page {
	my $self = shift;
	my $offset = ($_[0] > 0 ? 1 : -1);

	$self->call_hook('list_page', $offset);

	my $maxpage = floor(@{$self->{widget}->{content}} / $self->{height});
	my $page = floor($self->{widget}->{index} / $self->{height});

	$page += $offset;

	$page = 0        if $page < 0;
	$page = $maxpage if $page > $maxpage;

	if (!$page && $self->{widget}->{index} < $self->{height}) {
		$self->{widget}->{index} = 0;
	} else {
		$self->{widget}->{index} = $self->{height} * $page;
		$self->{widget}->{index} += $self->{height} - 1 if $offset < 0;
	}

	$self->fill();
}

1;
