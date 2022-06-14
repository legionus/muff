package Muff::UI::Widget::Key;

use strict;
use warnings FATAL => qw(all);

use Curses;

use Muff::UI::Widget::Base;

use parent 'Muff::UI::Widget::Base';

sub CKEY_ESCAPE { "\x1b" }
sub CKEY_TAB    { "\t"   }
sub CKEY_SPACE  { " "    }

sub to_key {
	my $raw = shift;

	my $smap = {
		"^["   => CKEY_ESCAPE(),
		"\cH"  => KEY_BACKSPACE(),
		"\c?"  => KEY_DC(),
		"\cD"  => KEY_DC(),
		"\n"   => KEY_ENTER(),
		"\cM"  => KEY_ENTER(),
		"OH"   => KEY_HOME(),
		"[7~"  => KEY_HOME(),
		"[1~"  => KEY_HOME(),
		"OI"   => KEY_BTAB(), # My xterm under solaris
		"[Z"   => KEY_BTAB(), # My xterm under Redhat Linux
		"OF"   => KEY_END(),
		"[4~"  => KEY_END(),
		"[5~"  => KEY_PPAGE(),
		"[6~"  => KEY_NPAGE(),
	};
	if (my $key = $smap->{$raw}) {
		return $key;
	}
	return $raw;
}

sub new {
	my ($class, $value, $is_func) = @_;
	my $self = {};

	$self->{func} = $is_func;
	$self->{value} = $value;
	$self->{key} = to_key($self->{value});

	return bless $self, $class;
}

sub value {
	my $self = shift;
	return $self->{value};
}

sub key {
	my $self = shift;
	return $self->{key};
}

sub string {
	my $self = shift;
	my $key = $self->{key};

	if ($key eq CKEY_ESCAPE) {
		$key = '<KEY_ESCAPE>';
	}
	elsif ($key eq CKEY_TAB) {
		$key = '<KEY_TAB>';
	}
	elsif ($key eq CKEY_SPACE) {
		$key = '<KEY_SPACE>';
	}
	# Control characters. Change them into something printable
	# via Curses' unctrl function.
	elsif ($key lt ' ') {
		$key = '<' . uc(unctrl($key)) . '>';
	}

	# Extended keys get translated into their names via Curses'
	# keyname function.
	elsif ($key =~ /^\d{2,}$/) {
		$key = '<' . uc(keyname($key)) . '>';
	}

	return $key;
}

1;
