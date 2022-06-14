package Muff::Mailbox::Lister;

use strict 'refs';
use warnings;

use Date::Parse;

sub new {
	my $class = shift;
	my $self = {
		nodes => {},
		error => sub { print "$_[0]\n" if @_; },
	};
	bless $self, $class;
	return $self;
}

sub __by_thread {
	$a->{timestamp} <=> $b->{timestamp} || $a->{subject} cmp $b->{subject};
}

sub __get_node {
	my ($self, $id) = @_;

	if (!$self->{nodes}->{$id}) {
		$self->{nodes}->{$id} = {
			id        => $id,
			timestamp => 0,
			subject   => "",
			message   => undef,
			parent    => undef,
			childs    => {},
			n_subs    => 0,
		};
	}

	return $self->{nodes}->{$id};
}

sub __is_loop {
	my ($node, $id) = @_;
	while ($node) {
		return 1 if $node->{id} eq $id;
		$node = $node->{parent};
	}
	return 0;
}

sub __link_nodes {
	my ($self, $refs) = @_;

	my $parent;

	foreach my $id (@$refs) {
		next if __is_loop($parent, $id);

		my $node = $self->__get_node($id);

		if (!$node->{parent}) {
			$node->{parent} = $parent;
			$parent->{childs}->{$id} = $node
				if !$parent->{childs}->{$id};
		}

		$parent = $node;
	}
}

sub __get_references {
	my ($self, $head) = @_;

	my @references = ();
	my %seen;

	if (my $refs = $head->get('references')) {
		while ($refs =~ s/\<(\S+\@\S+)\>//s) {
			if (!$seen{$1}) {
				push(@references, $1);
				$seen{$1} = 1;
			}
		}
	}
	if (my $irt  = $head->get('in-reply-to')) {
		for ($irt =~ m/\<(\S+\@\S+)\>/) {
			if (!$seen{$1}) {
				push(@references, $1);
			}
		}
	}
	return \@references;
}

sub parse {
	my ($self, $folder) = @_;

	foreach my $message ($folder->messages) {
		my $msgid = $message->messageId;
		my $head  = $message->head or next;
		my $node  = $self->__get_node($msgid);

		if ($node->{message}) {
			$self->error("WARNING: duplicate message ID: " . $msgid);
			next;
		}

		$node->{message} = $message;
		$node->{subject} = $message->study('subject') || "";
		$node->{timestamp} = str2time($message->get("date")) || 0;

		my $refs = $self->__get_references($head);
		push @$refs, $msgid;

		$self->__link_nodes($refs);
	}

	foreach my $id (keys %{$self->{nodes}}) {
		my $node = $self->{nodes}->{$id};

		next if $node->{message};

		if ($node->{parent}) {
			foreach my $cid (keys %{$node->{childs}}) {
				next if $node->{parent}->{childs}->{$cid};
				$node->{parent}->{childs}->{$cid} = $node->{childs}->{$cid};
			}
			delete $node->{parent}->{childs}->{$id};
		}

		foreach my $cid (keys %{$node->{childs}}) {
			$node->{childs}->{$cid}->{parent} = $node->{parent};
		}

		delete $self->{nodes}->{$id};
	}

	foreach my $node (values %{$self->{nodes}}) {
		for (my $n = $node; $n; $n = $n->{parent}) {
			$n->{n_subs} += 1;
		}
	}
}

sub heads {
	my $self = shift;
	return sort __by_thread grep { !$_->{parent} } values %{$self->{nodes}};
}

my $_cross    = "\N{U+251C}\N{U+2500}>";
my $_corner   = "\N{U+2514}\N{U+2500}>";
my $_vertical = "\N{U+2502} ";
my $_space    = "  ";

sub __walk {
	my ($self, $handler, $node, $stack, $is_last) = @_;

	die "Empty node found: $node->{id}"
		if !$node->{message};

	my $prefix = "";

	if ($node->{parent}) {
		if ($is_last) {
			$prefix = join "", @$stack, $_corner;
			push @$stack, $_space;
		} else {
			$prefix = join "", @$stack, $_cross;
			push @$stack, $_vertical;
		}
	}

	$handler->($node, $prefix);

	my @childs = sort __by_thread values %{$node->{childs}};

	while (my ($i, $child) = each @childs) {
		$self->__walk($handler, $child, $stack, ($i == @childs - 1));
	}

	pop @$stack if $node->{parent};
}

sub walk {
	my ($self, $handler) = @_;

	my @nodes = sort __by_thread grep { !$_->{parent} } values %{$self->{nodes}};

	while (my ($i, $node) = each @nodes) {
		$self->__walk($handler, $node, [], 0);
	}
}

1;
