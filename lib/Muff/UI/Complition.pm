package Muff::UI::Complition;

use strict;
use warnings FATAL => qw(all);

use Curses;

sub create {
	my $screen = shift;
	my $winname = shift;
	my $fromwin = shift;
	my $prefix = shift;
	my $lines = shift;

	my $size = @{$lines};
	my $width = 0;

	$size = 5 if $size > 5;

	foreach my $line (@{$lines}) {
		$width = length($line) if length($line) > $width;
	}

	my $cursor = $fromwin->cursor();

	$cursor->{x} += $fromwin->{x};
	$cursor->{y} += $fromwin->{y};

	my $win = $screen->create('Window', {
			name => $winname,
			focusable => 0,
			popup => 1,
			min_height => $size,
			height => $size,
			width => $width + 2,
			y => $cursor->{y} - $size,
			x => $cursor->{x},
			color_fg => 'default',
			color_bg => 'black',
		});

	$win->create('List', {
			height => $win->{height},
			color_fg => 'white',
			content => $lines,
			context => {
				prefix => $prefix,
			},
			on => {
				list_setline => \&complition_setline,
			},
		});

	$win->draw();

	$fromwin->focus(1);
	$fromwin->refresh_widget();

	return $win;
}

sub complition_setline {
	my ($self, $i, $selected, $text) = @_;

	$self->{bin}->addstring($i, 0, " ");

	$self->{bin}->attron(A_BOLD | A_UNDERLINE);
	$self->{bin}->addstring($i, 1, $self->{context}->{prefix});
	$self->{bin}->attroff(A_BOLD | A_UNDERLINE);

	my $len = length($self->{context}->{prefix});

	$self->{bin}->addstring($i, 1 + $len, "" . substr($text, $len));
}

1;
