package Muff::Struct;

use strict;
use warnings FATAL => 'all';

use Carp;

sub TIEHASH {
	my $self = {};
	foreach (keys %{$_[1]}) {
		$self->{$_} = $_[1]->{$_};
	}
	bless $self, $_[0]
}
sub STORE {
	croak "assignment to an unknown field '$_[1]'"
		if ! exists $_[0]->{$_[1]};
	$_[0]->{$_[1]} = $_[2]
}
sub FETCH {
	croak "reading from an unknown field '$_[1]'"
		if ! exists $_[0]->{$_[1]};
	$_[0]->{$_[1]}
}
sub DELETE {
	croak "Deletion from a fixed structure is not supported";
	#delete $_[0]->{$_[1]}
}
sub CLEAR    { $_[0]->{$_} = undef foreach keys %{$_[0]} }
sub FIRSTKEY { my $a = scalar keys %{$_[0]}; each %{$_[0]} }
sub NEXTKEY  { each %{$_[0]} }
sub EXISTS   { exists $_[0]->{$_[1]} }
sub SCALAR   { scalar %{$_[0]} }

use Exporter 'import';
BEGIN { our @EXPORT_OK = qw(struct); }

sub struct {
	my %h;
	tie %h, 'Muff::Struct', $_[0];
	\%h
}

1;
