#!/usr/bin/perl

# Formal testing for Class::Inspector

# Do all the tests on ourself, since we know we will be loaded.

use strict;
use lib '../../../modules'; # Development testing
use lib '../lib';           # Installation testing
use UNIVERSAL 'isa';
use Test::Simple tests => 47;

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
ok( $filename eq File::Spec->catfile( "Class", "Inspector.pm" ), "->filename works correctly" );
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

sub _a_first { 1; }
sub dummy1 { 1; }
sub _dummy2 { 1; }
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
	and $methods->[0] eq '_a_first'
	and scalar @$methods == 14
	and scalar( grep { /dummy/ } @$methods ) == 3),
	"->methods works for inheriting class" );
ok( ! $ci->methods( $bad ), "->methods fails correctly" );

# Check the variety of different possible ->methods options

# Public option
$methods = $ci->methods( $ci, 'public' );
ok( (isa( $methods, 'ARRAY' ) 
	and $methods->[0] eq 'filename'
	and scalar @$methods == 9),
	"Public ->methods works for non-inheriting class" );
$methods = $ci->methods( 'Class::Inspector::Dummy', 'public' );
ok( (isa( $methods, 'ARRAY' ) 
	and $methods->[0] eq 'dummy1'
	and scalar @$methods == 11
	and scalar( grep { /dummy/ } @$methods ) == 2),
	"Public ->methods works for inheriting class" );
ok( ! $ci->methods( $bad ), "Public ->methods fails correctly" );

# Private option
$methods = $ci->methods( $ci, 'private' );
ok( (isa( $methods, 'ARRAY' ) 
	and $methods->[0] eq '_checkClass'
	and scalar @$methods == 1),
	"Private ->methods works for non-inheriting class" );
$methods = $ci->methods( 'Class::Inspector::Dummy', 'private' );
ok( (isa( $methods, 'ARRAY' ) 
	and $methods->[0] eq '_a_first'
	and scalar @$methods == 3
	and scalar( grep { /dummy/ } @$methods ) == 1),
	"Private ->methods works for inheriting class" );
ok( ! $ci->methods( $bad ), "Private ->methods fails correctly" );

# Full option
$methods = $ci->methods( $ci, 'full' );
ok( (isa( $methods, 'ARRAY' ) 
	and $methods->[0] eq 'Class::Inspector::_checkClass'
	and scalar @$methods == 10),
	"Full ->methods works for non-inheriting class" );
$methods = $ci->methods( 'Class::Inspector::Dummy', 'full' );
ok( (isa( $methods, 'ARRAY' ) 
	and $methods->[0] eq 'Class::Inspector::Dummy::_a_first'
	and scalar @$methods == 14
	and scalar( grep { /dummy/ } @$methods ) == 3),
	"Full ->methods works for inheriting class" );
ok( ! $ci->methods( $bad ), "Full ->methods fails correctly" );

# Expanded option
$methods = $ci->methods( $ci, 'expanded' );
ok( (isa( $methods, 'ARRAY' ) 
	and isa( $methods->[0], 'ARRAY' )
	and $methods->[0]->[0] eq 'Class::Inspector::_checkClass'
	and $methods->[0]->[1] eq 'Class::Inspector'
	and $methods->[0]->[2] eq '_checkClass'
	and isa( $methods->[0]->[3], 'CODE' )
	and scalar @$methods == 10),
	"Expanded ->methods works for non-inheriting class" );
$methods = $ci->methods( 'Class::Inspector::Dummy', 'expanded' );
ok( (isa( $methods, 'ARRAY' ) 
	and isa( $methods->[0], 'ARRAY' )
	and $methods->[0]->[0] eq 'Class::Inspector::Dummy::_a_first'
	and $methods->[0]->[1] eq 'Class::Inspector::Dummy'
	and $methods->[0]->[2] eq '_a_first'
	and isa( $methods->[0]->[3], 'CODE' )
	and scalar @$methods == 14
	and scalar( grep { /dummy/ } map { $_->[2] } @$methods ) == 3),
	"Expanded ->methods works for inheriting class" );
ok( ! $ci->methods( $bad ), "Expanded ->methods fails correctly" );

# Check clashing between options
ok( ! $ci->methods( $ci, 'public', 'private' ), "Public and private ->methods clash correctly" );
ok( ! $ci->methods( $ci, 'private', 'public' ), "Public and private ->methods clash correctly" );
ok( ! $ci->methods( $ci, 'full', 'expanded' ), "Full and expanded ->methods class correctly" );
ok( ! $ci->methods( $ci, 'expanded', 'full' ), "Full and expanded ->methods class correctly" );

# Check combining options
$methods = $ci->methods( $ci, 'public', 'expanded' );
ok( (isa( $methods, 'ARRAY' ) 
	and isa( $methods->[0], 'ARRAY' )
	and $methods->[0]->[0] eq 'Class::Inspector::filename'
	and $methods->[0]->[1] eq 'Class::Inspector'
	and $methods->[0]->[2] eq 'filename'
	and isa( $methods->[0]->[3], 'CODE' )
	and scalar @$methods == 9),
	"Public + Expanded ->methods works for non-inheriting class" );
$methods = $ci->methods( 'Class::Inspector::Dummy', 'public', 'expanded' );
ok( (isa( $methods, 'ARRAY' ) 
	and isa( $methods->[0], 'ARRAY' )
	and $methods->[0]->[0] eq 'Class::Inspector::Dummy::dummy1'
	and $methods->[0]->[1] eq 'Class::Inspector::Dummy'
	and $methods->[0]->[2] eq 'dummy1'
	and isa( $methods->[0]->[3], 'CODE' )
	and scalar @$methods == 11 
	and scalar( grep { /dummy/ } map { $_->[2] } @$methods ) == 2),
	"Public + Expanded ->methods works for inheriting class" );
ok( ! $ci->methods( $bad ), "Expanded ->methods fails correctly" );

# Done
