package Muff::UI::Screen;

use strict;
use warnings FATAL => qw(all);

use Text::Wrap;

use Muff::UI::Widget::Screen;

sub create {
	my $config = shift;

	my $screen = Muff::UI::Widget::Screen->new({
			config => $config,
			onkey => {
				'<KEY_ESCAPE>' => sub {
					my $scr = shift;

					my $from = $scr->focus();
					my $win = $scr->get_window('main');

					$win = $win->{siblings}->next()->{data}
						if $from->is($win);

					$win->focus(1);

					$from->refresh_widget();
					$win->refresh_widget();

					1;
				},
			},
		});

	$screen->register_command(
		"quit",
		{
			usage => [ ":quit" ],
			descr => "Exit the program immediately without asking questions.",
		},
		sub {
			$_[0]->finish_loop();
			1;
		}
	);

	$screen->register_command(
		"resize",
		{
			usage => [
				":resize <window> [+N]",
				":resize <window> [-N]"
			],
			descr => "Increase or decrease target window height by N (default 1).",
		},
		sub {
			my $scr = shift;
			my $winname = shift;
			my $delta = @_ ? shift : 1;

			my $win = $scr->get_window($winname);
			return if !$win;

			$win->change_height($delta);
			$win->refresh_widget();

			$win = $scr->get_window('main');
			$win->refresh_widget();

			1;
		}
	);

	$screen->register_command(
		"windows",
		{
			usage => [ ":windows" ],
			descr => "TODO",
		},
		sub {
			my ($scr) = @_;
			my $text = "";

			if ($scr->{childs}) {
				$screen->{childs}->walk(sub {
						if (ref($_[0]) eq 'Muff::UI::Widget::Window' && ! $_[0]->{widget}->{popup}) {
							$text .= "window " . $_[0]->{name} . "\n";
						}

						0;
					});
			}

			if (my $win = $scr->get_window('output')) {
				Muff::UI::OnKey::close_window($win);
			}

			Muff::UI::Output::create($scr, "windows", $text);

			1;
		}
	);

	$screen->register_command(
		"list",
		{
			usage => [ ":list" ],
			descr => "Opens a list of mailboxes in the mail root directory ($config->{core}->{maildir}).",
		},
		sub {
			my $scr = shift;
			Muff::UI::Maillist::create($scr);

			1;
		}
	);

	$screen->register_command(
		"open",
		{
			usage => [ ":open" ],
			descr => "TODO",
		},
		sub {
			my $scr = shift;
			Muff::UI::Output::create($scr, "windows", $_[0]);
			1;
		}
	);

	$screen->register_command(
		"help",
		{
			usage => [ ":help [<command>]" ],
			descr => "Shows the description of the command or commands.",
		},
		sub {
			my $scr = shift;
			my @help;
			my $text;

			my $fmt = sub {
				my $cmd = shift;
				my $txt;

				local $Text::Wrap::columns = $scr->{width};

				$txt .= join("\n", map { "Command: $_" } @{$cmd->{help}->{usage}}) . "\n\n";
				$txt .= wrap("", "", $cmd->{help}->{descr}) . "\n";

				push @help, $txt;
			};

			if (@_) {
				my $args = shift;

				foreach my $name (keys %{$scr->{widget}->{commands}}) {
					if ($args->[0] eq $name) {
						$fmt->($scr->{widget}->{commands}->{$name});
						last;
					}
				}
			} else {
				foreach my $name (sort keys %{$scr->{widget}->{commands}}) {
					$fmt->($scr->{widget}->{commands}->{$name});
				}
			}

			if (@help) {
				Muff::UI::Output::create($scr, "help", join(("-" x $scr->{width}) . "\n", @help), 20);
			}
			1;
		}
	);

	return $screen;
}

1;
