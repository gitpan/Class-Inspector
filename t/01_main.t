#!/usr/local/bin/perl

# Formal testing for Class::Inspector

# Do all the tests on ourself, since we know we will be loaded.

use strict;
use lib '../../modules';
use lib '../lib'; # For installation testing
use UNIVERSAL 'isa';
use Test::Simple tests => 30;

# Set up any needed globals
use vars qw{$loaded $ci $bad};
BEGIN {
	$loaded = 0;
	$| = 1;
	
	# To make maintaining this a little faster,
	# $ci is defined as Class::Inspector, and 
	# $bad for a class we know doesn't exist.
	$ci = 'Class::Inspector';
	$bad = 'Class::Inspector::Nonexistant';
}




# Check their perl version
BEGIN {
	ok( $] >= 5.005, "Your perl is new enough" );
}
	




# Does the module load
END { ok( 0, 'Loads' ) unless $loaded; }
use Class::Inspector;
$loaded = 1;
ok( 1, 'Loads' );





# Check the seperator
my $SEP = $Class::Inspector::SEP;
ok( $SEP, "Seperator defined" );
ok( ($SEP eq '/' or $SEP eq '\\' or $SEP eq ':'), "Seperator appears valid ('$SEP')" );





# Check the good/bad class code
ok( $ci->_checkClass( $ci ), 'Class validator works for known valid' );
ok( $ci->_checkClass( $bad ), 'Class validator works for correctly formatted, but not installed' );
ok( $ci->_checkClass( 'A::B::C::D::E' ), 'Class validator works for long classes' );
ok( $ci->_checkClass( '::' ), 'Class validator allows main' );
ok( $ci->_checkClass( '::Blah' ), 'Class validator works for main aliased' );
ok( ! $ci->_checkClass(), 'Class validator failed for missing class' );
ok( ! $ci->_checkClass( '4teen' ), 'Class validator fails for number starting class' );
ok( ! $ci->_checkClass( 'Blah::%f' ), 'Class validator catches bad characters' );






# Check the loaded method
ok( $ci->loaded( $ci ), "->loaded detects loaded" );
ok( ! $ci->loaded( $bad ), "->loaded detects not loaded" );





# Check the file name methods
my $filename = $ci->filename( $ci );
ok( $filename eq "Class$SEP\Inspector.pm", "->filename works correctly" );
ok( $INC{$filename} eq $ci->loaded_filename( $ci ),
	"->loaded_filename works" );
ok( $INC{$filename} eq $ci->resolved_filename( $ci ),
	"->resolved_filename works" );





# Check the installed stuff
ok( $ci->installed( $ci ), "->installed detects installed" );
ok( ! $ci->installed( $bad ), "->installed detects not installed" );





# Check the functions
my $functions = $ci->functions( $ci );
ok( (isa( $functions, 'ARRAY' )
	and $functions->[0] eq '_checkClass'
	and scalar @$functions == 10),
	"->functions works correctly" );
ok( ! $ci->functions( $bad ), "->functions fails correctly" );





# Check function refs
$functions = $ci->function_refs( $ci );
ok( (isa( $functions, 'ARRAY' )
	and ref $functions->[0]
	and isa( $functions->[0], 'CODE' )
	and scalar @$functions == 10),
	"->function_refs works correctly" );
ok( ! $ci->functions( $bad ), "->function_refs fails correctly" );





# Check function_exists
ok( $ci->function_exists( $ci, 'installed' ),
	"->function_exists detects function that exists" );
ok( ! $ci->function_exists( $ci, 'nsfladf' ),
	"->function_exists fails for bad function" );
ok( ! $ci->function_exists( $ci ),
	"->function_exists fails for missing function" );
ok( ! $ci->function_exists( $bad, 'function' ),
	"->function_exists fails for bad class" );





# Check the methods method.
# First, defined a new subclass of Class::Inspector with some additional methods
package Class::Inspector::Dummy;

use strict;
use base 'Class::Inspector';

sub dummy1 { 1; }
sub dummy2 { 1; }
sub dummy3 { 1; }
sub installed { 1; }

package main;

my $methods = $ci->methods( $ci );
ok( (isa( $methods, 'ARRAY' ) 
	and $methods->[0] eq '_checkClass'
	and scalar @$methods == 10),
	"->methods works for non-inheriting class" );
$methods = $ci->methods( 'Class::Inspector::Dummy' );
ok( (isa( $methods, 'ARRAY' ) 
	and $methods->[0] eq '_checkClass'
	and scalar @$methods == 13
	and scalar( grep { /^dummy/ } @$methods ) == 3),
	"->methods works for inheriting class" );
ok( ! $ci->methods( $bad ), "->methods fails correctly" );





# Done
