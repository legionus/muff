package Muff::UI::Maillist;

use strict;
use warnings FATAL => qw(all);

use POSIX qw(strftime);
use File::Glob ':bsd_glob';

use Muff::UI::OnKey;

sub create {
	my $screen = shift;
	my $winname = 'boxlist';

	if (my $win = $screen->get_window($winname)) {
		Muff::UI::OnKey::close_window($win);
	}

	my $date_format = "%a %b %e %Y";
	my $_date = strftime($date_format, localtime());

	my $maildir = bsd_glob($screen->{widget}->{config}->{core}->{maildir}, GLOB_TILDE | GLOB_ERR);

	my $rootlen = length($maildir) + 1;
	my @dirs = ( $maildir );
	my @values;

	while (@dirs > 0) {
		my $dir = shift @dirs;
		my $dh;
		if (!opendir($dh, $dir)) {
			return Muff::UI::Error::create($screen, "Can't open: $dir: $!");
		}
		while (readdir $dh) {
			next if ($_ eq '.' || $_ eq '..' || $_ =~ /^\./);

			#my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks) = stat($filename);
			my @stats = stat("$dir/$_");

			if (-f "$dir/$_") {
				my $path = "$dir/$_";
				push(@values, {
					type => " mbox",
					name => substr($path, $rootlen),
					date => "(" . strftime($date_format, localtime($stats[9])) . ")",
					url  => "mbox://$path",
				});
				next;
			}
			if (-d "$dir/$_/cur" && -d "$dir/$_/new" && -d "$dir/$_/tmp") {
				my $path = "$dir/$_";
				push(@values, {
					type => " maildir",
					name => substr($path, $rootlen),
					date => "(" . strftime($date_format, localtime($stats[9])) . ")",
					url  => "maildir://$path",
				});
				next;
			}
			push(@dirs, "$dir/$_") if -d "$dir/$_";
		}
		closedir($dh);
	}

	@values = sort { $a->{type} cmp $b->{type} || $a->{name} cmp $b->{name} } @values;

	my $win = $screen->create('Window', {
			name => $winname,
			height => $screen->{height} - 2,
			color_fg => 'default',
			color_bg => 'black',
			removable => 1,
			onkey => {
				':' => \&Muff::UI::OnKey::cmdline,
			},
		});

	$win->create('ListBox', {
			height => $win->{height},
			content => \@values,
			focusable => 1,
			selectable => 0,
			fields => [
				{ name => "type", width => 10 },
				{ name => "date", width => length($_date) + 2 + 1 + 1 },
				{ name => "name" },
			],
			onkey => {
				'<KEY_TAB>'	=> \&Muff::UI::OnKey::change_focus,
				'<KEY_UP>'	=> \&Muff::UI::OnKey::select_previous,
				'<KEY_DOWN>'	=> \&Muff::UI::OnKey::select_next,
				'<KEY_PPAGE>'	=> \&Muff::UI::OnKey::page_previous,
				'<KEY_NPAGE>'	=> \&Muff::UI::OnKey::page_next,
				'<KEY_ENTER>'	=> sub {
					my $box = $_[0]->{widget}->{content}->[$_[0]->index()];
					$_[0]->{screen}->exec_command('open', $box->{url});
					1;
				},
			},
		});

	$win->focus(1);
	$win->draw();

	return $win;
}

1;
