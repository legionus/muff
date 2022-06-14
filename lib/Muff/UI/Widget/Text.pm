package Muff::UI::Widget::Text;

use strict;
use warnings FATAL => qw(all);

use Carp;
use Curses;

use Muff::Struct qw(struct);

use parent 'Muff::UI::Widget::Common';

sub new {
	my ($class, $args) = @_;

	my $self = $class->SUPER::new($args);

	$self->{widget} = struct {
		text => $args->{text},
	};

	my $me = bless($self, $class);

	$me->call_hook('text_create');
	return $me;
}

sub draw {
	my $self = shift;

	my $cpair = $self->{colors}->pair($self->{color_fg}, $self->{color_bg});

	croak("win object leak")
		if $self->{bin};

	$self->{bin} = newwin($self->{height}, $self->{width}, $self->{y}, $self->{x});

	$self->{bin}->bkgd($cpair);
	$self->{bin}->addstring(0, 0, $self->{widget}->{text} . "");
	$self->{bin}->refresh();

	$self->SUPER::draw();
}

sub text {
	my $self = shift;
	if (@_) {
		$self->clean();

		$self->{widget}->{text} = $_[0] . "";
		$self->{bin}->addstring(0, 0, $self->{widget}->{text} . "");
		$self->{bin}->refresh();
	}
	return $self->{widget}->{text};
}

sub clean {
	my $self = shift;

	$self->{widget}->{text} = "";

	$self->{bin}->move(0, 0);
	$self->{bin}->clrtoeol();
	$self->{bin}->refresh();
}

1;
