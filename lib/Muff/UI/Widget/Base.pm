package Muff::UI::Widget::Base;

use POSIX;
use Devel::Cycle -quiet;

sub new {
	return bless {}, $_[0];
}

sub DESTROY {
	my $self = shift;

	#find_cycle($self);
	#return;

	find_cycle($self, sub {
			my $path = shift;
			foreach (@$path) {
				my ($type, $index, $ref, $value) = @$_;
				print STDERR "circular reference found while destroying object of type " . ref($this) . "! reftype: $type\n";
				POSIX::_exit(42);
			}
		});
}

1;
