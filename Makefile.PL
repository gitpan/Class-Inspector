require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Class::Inspector',
	'VERSION_FROM' => 'lib/Class/Inspector.pm',
	'PREREQ_PM'    => {
		# Module dependencies
		'File::Spec'   => 0.82,

		# Test file dependencies
		'Test::More'   => 0,
	},
	($] >= 5.005) ? (
		'AUTHOR'     => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT'   => "Get information about a class and it's structure",
	) : (),
);
