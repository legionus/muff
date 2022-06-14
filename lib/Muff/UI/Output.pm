package Muff::UI::Output;

use strict;
use warnings FATAL => qw(all);

use Muff::UI::OnKey;

sub create {
	my $screen = shift;
	my $title = shift;
	my $text = shift;
	my $size = (@_ > 0 ? shift : 5);

	croak("failed to free up space: $size")
		if !$screen->freeup_height($size);

	my $win = $screen->create('Window', {
			name => 'output',
			min_height => $size,
			height => $size,
			color_fg => 'default',
			color_bg => 'black',
			removable => 1,
			onkey => {
				'<^W>'	=> \&Muff::UI::OnKey::close_window,
				':'	=> \&Muff::UI::OnKey::cmdline,
			},
		});

	$win->create('Label', {
			name => "status",
			focusable => 0,
			height => 1,
			text => "-" . $title . "-" x ($win->{width} - length($title) - 1),
			color_fg => 'white',
			color_bg => 'blue',
		});

	$win->create('List', {
			focusable => 1,
			name => "output",
			height => $win->{height} - 1,
			color_fg => 'white',
			selectable => 0,
			content => [ split('\n', $text) ],
			onkey => {
				'<KEY_TAB>'	=> \&Muff::UI::OnKey::change_focus,
				'<KEY_UP>'	=> \&Muff::UI::OnKey::select_previous,
				'<KEY_DOWN>'	=> \&Muff::UI::OnKey::select_next,
				'<KEY_PPAGE>'	=> \&Muff::UI::OnKey::page_previous,
				'<KEY_NPAGE>'	=> \&Muff::UI::OnKey::page_next,
				'<KEY_ENTER>'	=> sub { print STDERR $_[0]->index() . "\n"; 1; },
			},
		});

	$win->focus(1);
	$win->draw();

	return $win;
}

1;
