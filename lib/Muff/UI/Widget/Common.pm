package Muff::UI::Widget::Common;

use strict;
use warnings FATAL => qw(all);

use Carp;
use Curses;

use Muff qw(addrref);
use Muff::Struct qw(struct);
use Muff::DLinked;
use Muff::UI::Widget::Base;
use Muff::UI::Widget::Colors;

use parent 'Muff::UI::Widget::Base';

sub new {
	my ($class, $args) = @_;

	$args->{color_fg} = "default" if !$args->{color_fg};
	$args->{color_bg} = "default" if !$args->{color_bg};
	$args->{colors} = Muff::UI::Widget::Colors->new if !$args->{colors};
	$args->{focusable} = 0 if ! exists $args->{focusable};
	$args->{removable} = 0 if ! exists $args->{removable};
	$args->{context} = {} if ! exists $args->{context};
	$args->{on} = {} if ! exists $args->{on};

	my $self = struct {
		name		=> $args->{name},
		screen		=> $args->{screen},
		window		=> $args->{window},
		parent		=> $args->{parent},
		colors		=> $args->{colors},
		x		=> $args->{x},
		y		=> $args->{y},
		min_height	=> $args->{min_height},
		height		=> $args->{height},
		width		=> $args->{width},
		color_fg	=> $args->{color_fg},
		color_bg	=> $args->{color_bg},
		onkey		=> $args->{onkey},
		focusable	=> $args->{focusable},
		removable	=> $args->{removable},
		on		=> $args->{on},
		context		=> $args->{context},
		bin		=> undef,
		focus		=> 0,
		siblings	=> undef,
		childs		=> undef,
		widget		=> undef,
	};

	my $me = bless($self, $class);
	my $linked = Muff::DLinked->new($me);

	$self->{siblings} = $linked;

	if ($self->{parent}) {
		if ($self->{parent}->{childs}) {
			$self->{parent}->{childs}->append($linked);
		} else {
			$self->{parent}->{childs} = $linked;
		}
	}

	return $me;
}

sub destroy {
	my $self = shift;

	$self->{on}->{destroy}->($self)
		if $self->{on}->{destroy};

	$self->{widget} = undef;

	$self->{siblings}->destroy();
	$self->{siblings} = undef;

	if ($self->{childs}) {
		$_->destroy() foreach $self->{childs}->data();
		$self->{childs} = undef;
	}

	$self->{parent} = undef;
	$self->{window} = undef;
	$self->{screen} = undef;

	if ($self->{bin}) {
		$self->{bin}->delwin();
		$self->{bin} = undef;
	}

	return 1;
}

sub cursor {
	my $self = shift;
	my $cursor_x = my $cursor_y = 0;

	$self->{bin}->getyx($cursor_y, $cursor_x);

	return { y => $cursor_y, x => $cursor_x };
}

sub child_by_name {
	my $self = shift;
	my $name = shift;
	return $self->{childs}->walk(sub { return ($_[0]->{name} eq $name) })
		if $self->{childs};
	return undef;
}

sub refresh_widget {
	my $self = shift;
	my $force = (@_ > 0);

	$self->{bin}->touchwin() if $force;
	$self->{bin}->refresh();

	$self->{childs}->walk(sub {
			$_[0]->refresh_widget($force)
			if ! $_[0]->{focus};
			0;
		}) if $self->{childs};

	if (my $in_focus = $self->focus()) {
		$in_focus->refresh_widget($force)
	}
}

sub draw {
	my $self = shift;
	return if ! $self->{childs};
	$self->{childs}->walk(sub { $_[0]->draw() if ! $_[0]->{focus}; 0; });
	$self->{childs}->walk(sub { $_[0]->draw() if   $_[0]->{focus}; 0; });
}

sub drop_removable {
	my ($self, $needed) = @_;
	return if ! $self->{childs};

	my @available;

	$self->{childs}->walk(sub {
			if ($_[0]->{removable} && $_[0]->{height} >= $needed) {
				push @available, $_[0];
				return 1;
			}
			0;
		});

	croak("required space not found")
		if !@available;

	$_->destroy() foreach @available;
}

sub find_y {
	my ($self, $args) = @_;

	my $y = 0;

	if ($self->{childs}) {
		foreach my $child (sort { $a->{y} <=> $b->{y} } $self->{childs}->data()) {
			my $child_y = $child->{y} - $self->{y};

			if (($y + $args->{height}) <= $child_y) {
				last;
			}
			$y = $child_y + $child->{height};
		}
	}

	return $y;
}

sub create {
	my $self = shift;
	my $class = shift;
	my $args = shift;

	if ($args->{name}) {
		croak("A widget with '$args->{name}' name is already exists")
			if $self->child_by_name($args->{name});
	}

	my $fullclass = "Muff::UI::Widget::$class";

	eval "require $fullclass"
		if !$INC{"Muff/UI/Widget/$class.pm"};

	$args->{colors}   = $self->{colors};
	$args->{color_fg} = $self->{color_fg} if !$args->{color_fg};
	$args->{color_bg} = $self->{color_bg} if !$args->{color_bg};

	$args->{x} = 0
		if ! exists $args->{x};

	$args->{min_height} = 1
		if ! exists $args->{min_height};

	my $is_second_try = 0;
	AGAIN: {
		if (! exists($args->{y}) && (exists($args->{height}) || exists($args->{min_height}))) {
			$args->{height} = $args->{min_height}
				if ! exists $args->{height};

			$args->{y} = $self->find_y($args);
		}

		$args->{height} = $self->{height}
			if ! exists $args->{height};

		my $height = $self->{height} - $args->{y};

		if ($height < $args->{height}) {
			if ($height < $args->{min_height}) {
				croak "not enough space for the widget"
					if $is_second_try;

				$self->drop_removable($args->{min_height});
				delete $args->{y};
				$is_second_try = 1;

				next AGAIN;
			}

			carp "widget height is too big, reduce it from $args->{height} to $height";
			$args->{height} = $height;
		}
	}

	$args->{width}  = $self->{width}
		if ! exists $args->{width};

	$args->{x} += $self->{x};
	$args->{y} += $self->{y};

	$args->{screen} = $self->{screen};
	$args->{window} = $self->{window}
		if !$args->{window};

	$args->{parent} = $self;

	my $child = eval { $fullclass->new($args) };
	croak($@) if $@;

	$self->focus(1)
		if $self->{focus};

	return $child;
}

sub focus {
	my $self = shift;

	if (!@_) {
		return $self->{childs}->walk(sub { return $_[0]->{focus} })
			if $self->{childs};
		return undef;
	}

	my $focus = ($_[0] ? 1 : 0);

	return
		if $self->{focus} == $focus;
	$self->{focus} = $focus;

	if ($focus) {
		print STDERR "FOCUS ON  = ".ref($self)."\n"
			if $ENV{MUFF_DEBUG};

		$self->{siblings}->walk(sub {
				$_[0]->focus(0) if ! $self->is($_[0]);
				0;
			});

		my $focusable;
		my @in_focus;

		$self->{childs}->walk(sub {
				$focusable = $_[0]
					if !$focusable && $_[0]->{focusable};

				push @in_focus, $_[0]
					if $_[0]->{focus};

				0;
			}) if $self->{childs};

		if (@in_focus > 1) {
			$_->focus(0) foreach @in_focus;
			@in_focus = ();
		}

		$focusable->focus(1)
			if $focusable && !@in_focus;
	} else {
		print STDERR "FOCUS OFF = ".ref($self)."\n"
			if $ENV{MUFF_DEBUG};

		$self->{childs}->walk(sub { $_[0]->focus(0); 0; })
			if $self->{childs};
	}
}

sub move_cursor_left {
	my $self = shift;
	my $cursor_x = my $cursor_y = 0;

	$self->{bin}->getyx($cursor_y, $cursor_x);
	$self->{bin}->move($cursor_y, $cursor_x - 1);
	$self->{bin}->refresh();
}

sub move_cursor_right {
	my $self = shift;
	my $cursor_x = my $cursor_y = 0;

	$self->{bin}->getyx($cursor_y, $cursor_x);
	$self->{bin}->move($cursor_y, $cursor_x + 1);
	$self->{bin}->refresh();
}

sub move_cursor_up {
	my $self = shift;
	my $cursor_x = my $cursor_y = 0;

	$self->{bin}->getyx($cursor_y, $cursor_x);
	$self->{bin}->move($cursor_y - 1, $cursor_x);
	$self->{bin}->refresh();
}

sub move_cursor_down {
	my $self = shift;
	my $cursor_x = my $cursor_y = 0;

	$self->{bin}->getyx($cursor_y, $cursor_x);
	$self->{bin}->move($cursor_y + 1, $cursor_x);
	$self->{bin}->refresh();
}

sub move_cursor_home {
	my $self = shift;
	my $cursor_x = my $cursor_y = 0;

	$self->{bin}->getyx($cursor_y, $cursor_x);
	$self->{bin}->move($cursor_y, 0);
	$self->{bin}->refresh();
}

sub move_cursor_end {
	my $self = shift;
	my $cursor_x = my $cursor_y = 0;

	$self->{bin}->getyx($cursor_y, $cursor_x);
	$self->{bin}->move($cursor_y, $self->{width} - 1);
	$self->{bin}->refresh();
}

sub change_height {
	my ($self, $delta) = @_;

	my $new_height = $self->{height} + $delta;

	my $max_height = $self->{parent}
		? $self->{parent}->{height}
		: $self->{screen}->{height};
	$max_height -= $self->{y};

	return if $new_height < 1 || $new_height > $max_height;

	if ($delta < 0) {
		$self->{bin}->move($new_height, 0);
		$self->{bin}->clrtobot();
		$self->{bin}->refresh();
	}

	$self->{height} = $new_height;

	$self->{bin}->resize($self->{height}, $self->{width});
	$self->{bin}->refresh();

	$self->{childs}->walk(sub {
			return 0 if $_[0]->{height} <= $_[0]->{min_height};

			if ($delta < 0) {
				my $space = $_[0]->{height} - $_[0]->{min_height};

				if ($space < -$delta) {
					$_[0]->change_height(-$space);
					$delta += $space;
				} else {
					$_[0]->change_height($delta);
					$delta = 0;
				}
			} else {
				$_[0]->change_height($delta);
				$delta = 0;
			}

			return 1 if $delta <= 0;
			return 0;
		}) if $self->{childs};
}

sub is {
	my ($self, $widget) = @_;
	return (addrref($self) == addrref($widget));
}

sub call_hook {
	my $self = shift;
	my $name = shift;
	return undef if ! $self->{on} || ! $self->{on}->{$name};
	return $self->{on}->{$name}->($self, @_);
}

1;
