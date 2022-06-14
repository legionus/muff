#!/usr/bin/env perl

use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	ABSTRACT      => 'Simple mail client.',
	AUTHOR        => 'Gladkov Alexey <gladkov.alexey@gmail.com>',
	NAME          => 'App::Muff',
	VERSION       => '0.1',
	LICENSE       => 'GPL-2-or-later',
	EXE_FILES     => [ 'bin/muff' ],
	PREREQ_PM     => {
		'Carp'                  => '1.52',
		'Config'                => '5.034000',
		'Curses'                => '1.38',
		'Cwd'                   => '0',
		'Date::Parse'           => '0',
		'Date::Parse'           => '2.33',
		'DynaLoader'            => '1.50',
		'Exporter'              => '5.76',
		'Exporter::Heavy'       => '5.76',
		'File::Basename'        => '0',
		'File::Glob'            => '0',
		'File::Glob'            => '1.33',
		'Term::ReadKey'         => '2.38',
		'Text::ParseWords'      => '0',
		'Text::Wrap'            => '0',
		'Time::Local'           => '1.30',
		'Time::Zone'            => '2.24',
	},
);

WriteMakefile(%WriteMakefileArgs);
