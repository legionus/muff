package Muff::UI::Widget::Label;

use strict;
use warnings FATAL => qw(all);

use Carp;
use Curses;

use Muff::Struct qw(struct);

use parent 'Muff::UI::Widget::Common';

sub new {
	my ($class, $args) = @_;

	$args->{height} = 1;

	my $self = $class->SUPER::new($args);

	$self->{widget} = struct {
		text => $args->{text} || "",
	};

	my $me = bless($self, $class);

	$me->call_hook('label_create');
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

	$self->SUPER::draw;
}

1;
