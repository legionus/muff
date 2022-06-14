package Muff::UI::Welcome;

use strict;
use warnings FATAL => qw(all);

use Muff::UI::OnKey;

sub create {
	my $screen = shift;

	my $win = $screen->create('Window', {
			name => 'welcome',
			height => $screen->{height} - 2,
			color_fg => 'default',
			color_bg => 'black',
			removable => 1,
			onkey => {
				':' => \&Muff::UI::OnKey::cmdline,
			},
		});

	my $welcome = <<EOF;

Welcome to MUFF!

I don't know you, but there will be some interesting text about how cool perl is.
And how cool it is to write interactive programs on it.

EOF

	$win->create('List', {
			height => $win->{height},
			content => [ split('\n', $welcome) ],
			focusable => 1,
			selectable => 0,
			onkey => {
				'<KEY_TAB>'	=> \&Muff::UI::OnKey::change_focus,
				'<KEY_UP>'	=> \&Muff::UI::OnKey::select_previous,
				'<KEY_DOWN>'	=> \&Muff::UI::OnKey::select_next,
				'<KEY_PPAGE>'	=> \&Muff::UI::OnKey::page_previous,
				'<KEY_NPAGE>'	=> \&Muff::UI::OnKey::page_next,
			},
		});

	$win->focus(1);
	$win->draw();

	return $win;
}

1;
