package Muff::UI::Main;

use strict;
use warnings FATAL => qw(all);

use Muff::UI::OnKey;
use Muff::UI::Error;

sub close_complition {
	my $screen = shift;

	if (my $win = $screen->get_window('complition')) {
		$win->destroy();
		$screen->refresh_widget();
	}
}

sub complition {
	my ($self, $input) = @_;

	my $text = $self->text();
	my $screen = $self->{screen};

	close_complition($screen);

	return 1
		if length($text) == 0;

	my @variant = $screen->command_variants($text);

	return 1
		if @variant == 0;

	if (@variant == 1 && length($text) < length($variant[0]) && $input) {
		$self->move_cursor_end();
		$self->add_text(substr($variant[0], length($text)));
		return 1;
	}

	Muff::UI::Complition::create($screen, 'complition', $self, $text, \@variant);

	1;
}

sub create {
	my $screen = shift;

	my $win = $screen->create('Window', {
			name => 'main',
			y => $screen->{height} - 2,
			height => 2,
			color_fg => 'default',
			color_bg => 'black',
		});

	$win->create('Label', {
			name => "status",
			height => 1,
			text => "-" x $win->{width},
			color_fg => 'white',
			color_bg => 'blue',
		});

	$win->create('Input', {
			name => "prompt",
			height => 1,
			color_fg => 'white',
			onkey => {
				'<KEY_LEFT>'		=> \&Muff::UI::OnKey::move_cursor_left,
				'<KEY_RIGHT>'		=> \&Muff::UI::OnKey::move_cursor_right,
				'<KEY_HOME>'		=> \&Muff::UI::OnKey::move_cursor_home,
				'<KEY_END>'		=> \&Muff::UI::OnKey::move_cursor_end,
				'<KEY_BACKSPACE>'	=> sub {
					my $rc = Muff::UI::OnKey::backspace($_[0]);
					complition($_[0], 0);
					return $rc;
				},
				'<KEY_TAB>'		=> sub {
					return Muff::UI::OnKey::change_focus($_[0])
						if ! length($_[0]->text());
					return complition($_[0], 1);
				},
				'<KEY_ENTER>'		=> sub {
					my $text = $_[0]->text();

					$_[0]->clean();
					close_complition($_[0]->{screen});

					if (length($text)) {
						my $res = $_[0]->{screen}->command($text);

						Muff::UI::Error::create($_[0]->{screen}, $res->{text})
							if ref($res) eq 'Muff::UI::Widget::Error';
					}
					1;
				},
				'' => sub {
					return if $_[1]->{func};
					$_[0]->add_text($_[1]->key);
					complition($_[0], 0);
					1;
				}
			},
		});

	$win->focus(1);
	$win->draw();

	return $win;
}

1;
