package Muff::UI::OnKey;

use strict;
use warnings FATAL => qw(all);

sub do_exit           { $_[0]->finish_loop();            1; }
sub change_focus      { $_[0]->{screen}->change_focus(); 1; }
sub move_cursor_left  { $_[0]->move_cursor_left();       1; }
sub move_cursor_right { $_[0]->move_cursor_right();      1; }
sub move_cursor_home  { $_[0]->move_cursor_home();       1; }
sub move_cursor_end   { $_[0]->move_cursor_end();        1; }
sub backspace         { $_[0]->backspace();              1; }
sub select_previous   { $_[0]->select(-1);               1; }
sub select_next       { $_[0]->select(1);                1; }
sub page_previous     { $_[0]->page(-1);                 1; }
sub page_next         { $_[0]->page(1);                  1; }

sub cmdline {
	my ($self, $char) = @_;

	if (my $mainwin = $self->{screen}->get_window('main')) {
		my $focus = $self->focus();

		$focus->{window}->focus(0);
		$mainwin->focus(1);

		$focus->{window}->refresh_widget();
		$mainwin->refresh_widget();
		return 1;
	}
	return 0;
}

sub close_window {
	my $self = shift;

	my $size = $self->{height};
	my $focuswin = $self->{siblings}->prev()->{data};
	my $upperwin;

	$focuswin->get_window('main')
		if $focuswin->is($self);

	my @childs = sort { $a->{y} <=> $b->{y} } grep { ! $_->{widget}->{popup} } $self->{siblings}->data();

	for (my $i = 0; $i < @childs; $i++) {
		if ($childs[$i]->is($self)) {
			$upperwin = $childs[$i - 1] if $i;
			last;
		}
	}

	$self->destroy();

	if ($upperwin) {
		$upperwin->change_height($size);
		$upperwin->refresh_widget();
	}

	$focuswin->focus(1);
	$focuswin->refresh_widget();

	1;
}

1;
