package Muff::UI::Widget::Colors;

use strict;
use warnings FATAL => qw(all);

use Carp;
use Curses;
use POSIX;

use Muff::UI::Widget::Base;

use parent 'Muff::UI::Widget::Base';

sub new {
	my ($class) = @_;

	eval { start_color };
	die if $@;

	my $self = {
		cmap => {
			default => -1,
			black   => COLOR_BLACK,
			red     => COLOR_RED,
			green   => COLOR_GREEN,
			yellow  => COLOR_YELLOW,
			blue    => COLOR_BLUE,
			magenta => COLOR_MAGENTA,
			cyan    => COLOR_CYAN,
			white   => COLOR_WHITE,
		},
		next_color => 8,
		pmap       => {},
		next_pair  => 1,
	};

	return bless $self, $class;
}

sub color {
	my $self = shift;
	my $name = shift;

	if (@_) {
		my ($r, $g, $b) = @_;

		croak("Too many colors defined")
			unless $self->{next_color} <= POSIX::SHRT_MAX;

		croak("The value for red is too high")   unless $r < 1000;
		croak("The value for green is too high") unless $g < 1000;
		croak("The value for blue is too high")  unless $g < 1000;

		croak("The value for red is too low")   unless $r > 0;
		croak("The value for green is too low") unless $g > 0;
		croak("The value for blue is too low")  unless $g > 0;

		eval { init_color($self->{next_color}, $r, $g, $b) };
		croak("$@") if $@;

		$self->{cmap}->{$name} = $self->{next_color};
		$self->{next_color}++;
	}

	croak("Color not found")
		unless $self->{cmap}->{$name};

	return $self->{cmap}->{$name};
}

sub pair {
	my $self = shift;
	my $fg = shift;
	my $bg = shift;

	croak("Too many color pairs defined")
		unless $self->{next_pair} <= POSIX::SHRT_MAX;

	croak("Background color '$bg' not found")
		unless defined $self->{cmap}->{$bg};
	croak("Foreground color '$fg' not found")
		unless defined $self->{cmap}->{$fg};

	my $pair = "$bg:$fg";

	unless (defined $self->{pmap}->{$pair}) {
		eval { init_pair($self->{next_pair}, $self->{cmap}->{$fg}, $self->{cmap}->{$bg}) };
		croak("$@") if $@;

		$self->{pmap}->{$pair} = $self->{next_pair};
		$self->{next_pair}++;
	}

	return COLOR_PAIR($self->{pmap}->{$pair});
}

1;
