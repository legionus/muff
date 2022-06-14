package Muff::UI::Widget::Input;

use strict;
use warnings FATAL => qw(all);

use Carp;
use Curses;

use Muff::Struct qw (struct);

use parent 'Muff::UI::Widget::Common';

sub new {
	my ($class, $args) = @_;

	$args->{focusable} = 1;
	$args->{height} = 1;

	my $self = $class->SUPER::new($args);

	$self->{widget} = struct {
		prompt => ":",
		text => "",
	};

	my $me = bless($self, $class);

	$me->call_hook('input_create');
	return $me;
}

sub draw {
	my $self = shift;

	my $cpair = $self->{colors}->pair($self->{color_fg}, $self->{color_bg});

	croak("win object leak")
		if $self->{bin};

	$self->{bin} = newwin($self->{height}, $self->{width}, $self->{y}, $self->{x});

	$self->{bin}->bkgd($cpair);
	$self->{bin}->addstring(0, 0, $self->{widget}->{prompt} . $self->{widget}->{text} . "");
	$self->{bin}->refresh();

	$self->SUPER::draw();
}

sub move_cursor_left {
	my $self = shift;
	my $cursor_x = my $cursor_y = 0;

	$self->{bin}->getyx($cursor_y, $cursor_x);
	$self->SUPER::move_cursor_left()
		unless ($cursor_x - 1) < length($self->{widget}->{prompt});
}

sub move_cursor_right {
	my $self = shift;
	my $cursor_x = my $cursor_y = 0;

	$self->{bin}->getyx($cursor_y, $cursor_x);
	$self->SUPER::move_cursor_right()
		unless ($cursor_x + 1) > (length($self->{widget}->{prompt}) + length($self->{widget}->{text}));
}

sub move_cursor_home {
	my $self = shift;
	$self->{bin}->move(0, length($self->{widget}->{prompt}));
	$self->{bin}->refresh();
}

sub move_cursor_end {
	my $self = shift;
	$self->{bin}->move(0, length($self->{widget}->{prompt}) + length($self->{widget}->{text}));
	$self->{bin}->refresh();
}

sub add_text {
	my $self = shift;
	my $text = shift;
	my $cursor_x = my $cursor_y = 0;

	$self->{bin}->getyx($cursor_y, $cursor_x);

	my $offset = $cursor_x - length($self->{widget}->{prompt});
	my $suffix = $text . substr($self->{widget}->{text}, $offset);

	$self->{widget}->{text} = substr($self->{widget}->{text}, 0, $offset) . $suffix;

	$self->{bin}->addstring($suffix);
	$self->{bin}->move($cursor_y, $cursor_x + length($text));
	$self->{bin}->refresh();
}

sub backspace {
	my $self = shift;
	my $cursor_x = my $cursor_y = 0;

	$self->{bin}->getyx($cursor_y, $cursor_x);

	return if ($cursor_x - 1) < length($self->{widget}->{prompt});

	my $offset = $cursor_x - length($self->{widget}->{prompt});
	my $suffix = substr($self->{widget}->{text}, $offset);

	$self->{widget}->{text} = substr($self->{widget}->{text}, 0, $offset - 1) . $suffix;

	$self->{bin}->move($cursor_y, $cursor_x - 1);
	$self->{bin}->clrtoeol();
	$self->{bin}->addstring($suffix);
	$self->{bin}->move($cursor_y, $cursor_x - 1);
	$self->{bin}->refresh();
}

sub text {
	my $self = shift;
	$self->{widget}->{text};
}

sub clean {
	my $self = shift;

	$self->{widget}->{text} = "";

	$self->{bin}->move(0, length($self->{widget}->{prompt}));
	$self->{bin}->clrtoeol();
	$self->{bin}->refresh();
}

1;
