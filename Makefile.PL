require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Class::Inspector',
	'VERSION_FROM' => 'lib/Class/Inspector.pm',
	'PREREQ_PM'    => {
		'Class::ISA' => 0,
	},
	($] >= 5.005) ? (
		'AUTHOR'     => 'Adam Kennedy (adam@ali.as)',
		'ABSTRACT'   => "Get information about a class and it's structure",
	) : (),
);
