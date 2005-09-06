use inc::Module::Install;

name          ( 'Class-Inspector'              );
abstract      ( 'Get information about a class and its structure' );
author        ( 'Adam Kennedy <cpan@ali.as>' );
version_from  ( 'lib/Class/Inspector.pm'     );
requires      ( 'perl'            => '5.005' );
requires      ( 'File::Spec'      => '0.82'  );
build_requires( 'Test::More'      => '0.47'  );
auto_install  (                              );

&WriteAll;

require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'         => 'Class::Inspector',
	'VERSION_FROM' => 'lib/Class/Inspector.pm',
	'PREREQ_PM'    => {
		# Module dependencies
		'File::Spec'   => '0.82',

		# Test file dependencies
		'Test::More'   => '0.47',
	},
	($] >= 5.005) ? (
		'AUTHOR'     => 'Adam Kennedy (cpan@ali.as)',
		'ABSTRACT'   => "Get information about a class and it's structure",
	) : (),
);
