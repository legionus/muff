package Muff::UI::Widget::ListBox;

use strict;
use warnings FATAL => qw(all);

use Carp;
use Curses;

use Muff::Struct qw(struct);

use parent 'Muff::UI::Widget::Common';

sub new {
	my ($class, $args) = @_;

	$args->{focusable} = 1;

	my $self = $class->SUPER::new($args);

	$self->{widget} = struct {
		fields  => $args->{fields},
		content => $args->{content} || [],
	};

	my $me = bless($self, $class);

	$me->call_hook('listbox_create');

	$me->create_columns(0);
	return $me;
}

sub create_columns {
	my $self = shift;
	my $index = shift;

	my $x = 0;
	my $width = $self->{width};

	while (my ($i, $field) = each (@{$self->{widget}->{fields}})) {
		croak("There is no room left in the window for another column")
			if !$width;

		$field->{width} = $width if ! exists $field->{width};

		my $column = $self->create('List', {
				x         => $x,
				y         => 0,
				width     => $field->{width},
				height    => $self->{height},
				color_fg  => $field->{color_fg} || $self->{color_fg},
				color_bg  => $field->{color_bg} || $self->{color_bg},
				focusable => $self->{focusable},
				field     => $field->{name},
				content   => $self->{widget}->{content},
				on        => $self->{on},
				index     => $index,
			});

		$x += $field->{width};
		$width -= $field->{width};

		$column->focus(1) if $self->{focus} && ! $i;
	}
}

sub select {
	my ($self, $value) = @_;
	$self->call_hook('listbox_select', $value);
	$self->{childs}->walk(sub { $_[0]->select($value); 0; });
	$self->refresh_widget();
}

sub page {
	my ($self, $value) = @_;
	$self->call_hook('listbox_page', $value);
	$self->{childs}->walk(sub { $_[0]->page($value); 0; });
	$self->refresh_widget();
}

sub change_height {
	my ($self, $delta) = @_;

	$self->SUPER::change_height($delta);

	my $index = $self->index();

	if ($self->{childs}) {
		$_->destroy() foreach $self->{childs}->data();
		$self->{childs} = undef;
	}

	$self->{bin}->delwin();
	$self->{bin} = undef;

	$self->create_columns($index);
	$self->draw();
}

sub index {
	my $self = shift;
	my $in_focus = $self->focus();
	return 0 if !$in_focus;
	return $in_focus->index();
}

sub draw {
	my $self = shift;
	my $cpair = $self->{colors}->pair($self->{color_fg}, $self->{color_bg});

	croak("win object leak")
		if $self->{bin};

	$self->{bin} = newwin($self->{height}, $self->{width}, $self->{y}, $self->{x});

	$self->{bin}->bkgd($cpair);
	$self->{bin}->refresh();

	$self->SUPER::draw();
}

1;
