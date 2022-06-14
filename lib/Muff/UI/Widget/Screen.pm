package Muff::UI::Widget::Screen;

use strict;
use warnings FATAL => qw(all);

use Carp;
use Curses;
use Text::ParseWords;

use Muff qw(addrref);
use Muff::Struct qw(struct);
use Muff::UI::Widget::Error;
use Muff::UI::Widget::Key;

use parent 'Muff::UI::Widget::Common';

sub new {
	my ($class, $args) = @_;

	my $win = initscr();
	noecho();
	cbreak();
	use_default_colors();
	#curs_set(0);

	$args->{x}          = 0;
	$args->{y}          = 0;
	$args->{min_height} = $LINES;
	$args->{height}     = $LINES;
	$args->{width}      = $COLS;

	my $self = $class->SUPER::new($args);

	$self->{screen} = $self;
	$self->{bin}    = $win;
	$self->{focus}  = 1;

	$self->{widget} = struct {
		config   => $args->{config},
		commands => {},
		finish   => 0,
	};

	my $me = bless($self, $class);

	$me->call_hook('screen_create');
	return $me;
}

sub get_window {
	my ($self, $name) = @_;
	return undef if ! $self->{childs};
	return $self->{childs}->walk(sub {
			return (ref($_[0]) eq 'Muff::UI::Widget::Window' && $_[0]->{name} eq $name);
		});
}

sub freeup_height {
	my $self = shift;
	my $size = shift;
	my $ret = 0;

	if ($self->{childs}) {
		$self->{childs}->walk(sub {
				if (ref($_[0]) eq 'Muff::UI::Widget::Window' && ! $_[0]->{widget}->{popup}) {
					if ($_[0]->{min_height} <= ($_[0]->{height} - $size)) {
						$_[0]->change_height(-$size);
						$ret = 1;
						return 1;
					}
				}
				return 0;
			});
	}
	return $ret;
}

sub _validate_focus {
	my $o = shift;
	my $deep = shift;

	if ($ENV{MUFF_DEBUG}) {
		print STDERR (" " x $deep) . "* " . ref($o) .
			($o->{name} ? "(" . $o->{name} . ")" : "") .
			" focus=" . $o->{focus} .
			" addr=" . addrref($o) .
			"\n";
	}

	if ($o->{childs}) {
		my $childs = 0;
		my $in_focus = 0;
		$o->{childs}->walk(sub {
				$in_focus += $_[0]->{focus};
				$childs++;
				0;
			});

		croak("too many in focus: $in_focus")
			if $in_focus > 1;

		croak("bad focus: $childs childs in focus $in_focus")
			if $childs > 0 && $o->{focus} != $in_focus;

		$o->{childs}->walk(sub { _validate_focus($_[0], $deep + 2); 0; });
	}
};

sub validate_focus {
	my $self = shift;
	croak("not in focus")
		if ! $self->focus();
	_validate_focus($self, 0);
}

sub change_focus {
	my $self = shift;

	my $focus;
	for (my $o = $self->focus(); $o; $o = $o->focus()) {
		$focus = $o;
	}
	return if !$focus;

	my $new_focus;
	for (my $elem = $focus; !$new_focus && !$elem->is($elem->{screen});) {
		my $last = ($elem->{window}
			? $elem->{parent}->{childs}
			: $elem->{siblings});

		for (my $next = $elem->{siblings}->next(); addrref($next) != addrref($last); $next = $next->next()) {
			if ($next->{data}->{focusable}) {
				$new_focus = $next->{data};
				last;
			}
		}

		$elem = $elem->{parent}
			if $elem->{parent};
	}

	if ($new_focus) {
		$focus->focus(0);
		$new_focus->focus(1);

		$focus->refresh_widget();
		$new_focus->refresh_widget();
	}
}

my $rin = '';
vec($rin, fileno(STDIN), 1) = 1;

sub read_char {
	my $self = shift;
	my $focus = shift;

	$focus->{bin}->nodelay(1);
	$focus->{bin}->keypad(1);

	while (1) {
		my $rout = $rin;

		$! = 0;
		my $nfound = select($rout, undef, undef, undef);

		if ($nfound < 0) {
			croak("select: $!");
		}
		if ($nfound == 0) {
			next;
		}

		$focus->{bin}->untouchwin();
		my ($ch, $key) = $focus->{bin}->getchar();

		return Muff::UI::Widget::Key->new($key, 1) if defined $key;
		return Muff::UI::Widget::Key->new($ch,  0) if defined $ch;
	}
	croak("Bad key");
}

sub eventloop {
	my $self = shift;

	while (!$self->{widget}->{finish}) {
		my $focus;

		for (my $o = $self->focus(); $o; $o = $o->focus()) {
			$focus = $o;
		}
		next if !$focus;

		my $char = $self->read_char($focus);
		my $key = $char->string();

		print STDERR "KEY = {" . $key . "}\n"
			if $ENV{MUFF_DEBUG};

		for (my $o = $self; $o; $o = $o->focus()) {
			my $coderef;
			if ($o->{onkey}) {
				$coderef = $o->{onkey}->{$key} || $o->{onkey}->{""} || undef;
			}
			last if $coderef && $coderef->($o, $char);
		}
		$self->validate_focus();
	}
}

sub finish_loop {
	$_[0]->{screen}->{widget}->{finish} = 1;
}

sub register_command {
	my ($self, $cmdname, $help, $handler) = @_;

	croak("Command is already registered: $cmdname")
		if exists $self->{widget}->{commands}->{$cmdname};

	$self->{widget}->{commands}->{$cmdname} = struct {
		cmd  => $cmdname,
		help => struct({
			usage => $help->{usage},
			descr => $help->{descr},
		}),
		func => $handler,
	};
}

sub exec_command {
	my $self = shift;
	my $cmd = shift;
	my $args;

	$args = shift if @_;

	my $func;

	if ($self->{widget}->{commands}->{$cmd}) {
		$func = $self->{widget}->{commands}->{$cmd}->{func};
	}

	if (!$func) {
		my @candidates = $self->command_variants($cmd);

		$func = $self->{widget}->{commands}->{$candidates[0]}->{func}
			if @candidates == 1;

		return Muff::UI::Widget::Error->new("More than one command matches the '$cmd' prefix.PrUnknown command: " . join(', ', @candidates))
			if @candidates > 1;
	}

	if ($func) {
		return $func->($self, $args) if $args;
		return $func->($self);
	}
	return Muff::UI::Widget::Error->new("Unknown command: $cmd");
}

sub command {
	my ($self, $text) = @_;

	my @words = parse_line('\s+', 0, $text);
	return undef if !@words;

	my $cmd = shift @words;

	return $self->exec_command($cmd, \@words) if @words;
	return $self->exec_command($cmd);
}

sub command_variants {
	my ($self, $text) = @_;
	return grep { /^$text/ } keys %{$self->{widget}->{commands}};
}

1;
