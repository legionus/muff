package Muff::UI::Error;

use strict;
use warnings FATAL => qw(all);

use Muff::UI::OnKey;

sub create {
	my $screen = shift;
	my $text = shift;

	my $title = 'Error';
	my $size = 1 + split('\n', $text);

	if (my $win = $screen->get_window('error')) {
		Muff::UI::OnKey::close_window($win);
	}

	croak("failed to free up space: $size")
		if !$screen->freeup_height($size);

	my $win = $screen->create('Window', {
			name => 'error',
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
			color_bg => 'red',
		});

	$win->create('Text', {
			focusable => 1,
			name => "message",
			height => $win->{height} - 1,
			color_fg => 'white',
			text => $text,
			onkey => {
				'<KEY_TAB>'	=> \&Muff::UI::OnKey::change_focus,
			},
		});

	$win->focus(1);
	$win->draw();

	return $win;
}

1;
