package Muff::UI::Widget::Error;

use strict;
use warnings FATAL => qw(all);

use Carp;

use Muff::Struct qw(struct);
use Muff::UI::Widget::Base;

use parent 'Muff::UI::Widget::Base';

sub new {
	my ($class, $text) = @_;
	my $self = struct {
		text => $text,
	};
	bless $self, $class;
}

1;
