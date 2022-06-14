package Muff;

use strict;
use warnings FATAL => 'all';

use Scalar::Util qw(refaddr);

use Exporter 'import';
BEGIN {
	our @EXPORT_OK = qw(addrref);
}

sub addrref {
	return refaddr($_[0]) || -1;
}

1;
