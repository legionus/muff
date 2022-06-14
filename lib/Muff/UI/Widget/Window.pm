package Muff::UI::Widget::Window;

use strict;
use warnings FATAL => qw(all);

use Carp;
use Curses;

use Muff::Struct qw(struct);
use Muff::DLinked;

use parent 'Muff::UI::Widget::Common';

sub new {
	my ($class, $args) = @_;

	$args->{focusable} = 1;

	my $self = $class->SUPER::new($args);

	$self->{widget} = struct {
		popup => $args->{popup} || 0,
	};

	my $me = bless($self, $class);

	$me->call_hook('window_create');
	return $me;
}

sub draw {
	my $self = shift;

	my $cpair = $self->{colors}->pair($self->{color_fg}, $self->{color_bg});

	croak("win object leak")
		if $self->{bin};

	$self->{bin} = eval { newwin($self->{height}, $self->{width}, $self->{y}, $self->{x}) };
	croak($@) if $@;

	$self->{bin}->bkgd($cpair);
	$self->{bin}->refresh();

	$self->SUPER::draw;
}

sub create {
	my ($self, $class, $args) = @_;

	$args->{window} = $self;

	return $self->SUPER::create($class, $args);
}

1;
