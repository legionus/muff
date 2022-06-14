package Muff::DLinked;

use strict;
use warnings FATAL => qw(all);

use Carp;

use Muff qw(addrref);
use Muff::Struct qw(struct);

sub new {
	my ($class, $data) = @_;

	my $self = struct {
		prev => undef,
		next => undef,
		data => $data,
	};

	my $me = bless $self, $class;

	$me->next($me);
	$me->prev($me);

	return $me;
}

sub prev {
	my $self = shift;
	$self->{prev} = $_[0] if @_;
	return $self->{prev};
}

sub next {
	my $self = shift;
	$self->{next} = $_[0] if @_;
	return $self->{next};
}

sub append {
	my ($self, $new) = @_;

	$new->next($self);
	$new->prev($self->prev());

	$self->prev()->next($new);
	$self->prev($new);

	return 1;
}

sub destroy {
	my $self = shift;

	if (!$self->next() || !$self->prev()) {
		carp("An attempt to destroy an already destroyed element");
		return;
	}

	$self->prev()->next($self->next());
	$self->next()->prev($self->prev());

	$self->next(undef);
	$self->prev(undef);
	$self->{data} = undef;
}

sub walk {
	my ($self, $coderef) = @_;

	my $struct = $self;
	do {
		return $struct->{data} if $coderef->($struct->{data});
		$struct = $struct->next();
	} while(addrref($self) != addrref($struct));

	return undef;
}

sub data {
	my ($self, $coderef) = shift;
	my @data;

	my $struct = $self;
	do {
		push @data, $struct->{data};
		$struct = $struct->next();
	} while(addrref($self) != addrref($struct));

	return @data if wantarray;
	return \@data;
}

1;
