package Class::Inspector;

# Class::Inspector contains a range of static methods that can be used
# to get information about a class ( or package ) in a convient way.

# In this module we use $class to refer to OUR class, and $name to
# refer to class names being passed to us to be acted upon.
#
# Almost everything in here can be done in other ways, but a lot
# involve playing with special varables, symbol table, and the like.

# We don't want to use strict refs, since we do a lot of things in here
# that arn't strict refs friendly.
use strict 'vars', 'subs';
use File::Spec ();

# Globals
use vars qw{$VERSION $RE_SYMBOL $RE_CLASS $UNIX};
BEGIN {
	$VERSION = '1.06';

	# Predefine some regexs
	$RE_SYMBOL  = qr/\A[^\W\d]\w*\z/;
	$RE_CLASS   = qr/\A[^\W\d]\w*(?:(?:'|::)[^\W\d]\w*)*\z/;

	# Are we on Unix?
	$UNIX = !! ( $File::Spec::ISA[0] eq 'File::Spec::Unix' );
}





#####################################################################
# Basic Methods

# Is the class installed on the machine, or rather, is it available
# to Perl. This is basically just a wrapper around C<resolved_filename>.
# It is installed if it is either already available in %INC, or we
# can resolve a filename for it.
sub installed {
	my $class = shift;
	!! ($class->loaded_filename($_[0]) or $class->resolved_filename($_[0]));
}

# Is the class loaded.
# We do this by seeing if the namespace is "occupied", which basically
# means either we can find $VERSION, or any symbols other than child
# symbol table branches exist.
sub loaded {
	my $class = shift;
	my $name = $class->_class(shift) or return undef;

	# Are there any symbol table entries other than other namespaces
	foreach ( keys %{"${name}::"} ) {
		return 1 unless substr($_, -2, 2) eq '::';
	}

	'';
}

# Convert to a filename, in the style of
# First::Second -> First/Second.pm
sub filename {
	my $class = shift;
	my $name = $class->_class(shift) or return undef;
	File::Spec->catfile( split /(?:'|::)/, $name ) . '.pm';
}

# Resolve the full filename for the class.
sub resolved_filename {
	my $class = shift;
	my $filename = $class->_inc_filename(shift) or return undef;
	my @try_first = @_;

	# Look through the @INC path to find the file
	foreach ( @try_first, @INC ) {
		my $full = "$_/$filename";
		next unless -e $full;
		return $UNIX ? $full : $class->_inc_to_local($full);
	}

	# File not found
	'';
}

# Get the loaded filename for the class.
# Look the base filename up in %INC
sub loaded_filename {
	my $class = shift;
	my $filename = $class->_inc_filename(shift);
	$UNIX ? $INC{$filename} : $class->_inc_to_local($INC{$filename});
}





#####################################################################
# Sub Related Methods

# Get a reference to a list of function names for a class.
# Note: functions NOT methods.
# Only works if the class is loaded
sub functions {
	my $class = shift;
	my $name = $class->_class(shift) or return undef;
	return undef unless $class->loaded( $name );

	# Get all the CODE symbol table entries
	my @functions = sort grep { /$RE_SYMBOL/o }
		grep { defined &{"${name}::$_"} }
		keys %{"${name}::"};
	\@functions;
}

# As above, but returns a ref to an array of the actual 
# CODE refs of the functions.
# The class must be loaded for this to work.
sub function_refs {
	my $class = shift;
	my $name = $class->_class(shift) or return undef;
	return undef unless $class->loaded( $name );

	# Get all the CODE symbol table entries, but return
	# the actual CODE refs this time.
	my @functions = map { \&{"${name}::$_"} }
		sort grep { /$RE_SYMBOL/o }
		grep { defined &{"${name}::$_"} }
		keys %{"${name}::"};
	\@functions;
}

# Does a particular function exist
sub function_exists {
	my $class = shift;
	my $name = $class->_class( shift ) or return undef;
	my $function = shift or return undef;

	# Only works if the class is loaded
	return undef unless $class->loaded( $name );

	# Does the GLOB exist and it's CODE part exist
	defined &{"${name}::$function"};
}

# Get all the available methods for the class
sub methods {
	my $class = shift;
	my $name = $class->_class( shift ) or return undef;
	my @arguments = map { lc $_ } @_;

	# Process the arguments to determine the options
	my %options = ();
	foreach ( @arguments ) {
		if ( $_ eq 'public' ) {
			# Only get public methods
			return undef if $options{private};
			$options{public} = 1;

		} elsif ( $_ eq 'private' ) {
			# Only get private methods
			return undef if $options{public};
			$options{private} = 1;

		} elsif ( $_ eq 'full' ) {
			# Return the full method name
			return undef if $options{expanded};
			$options{full} = 1;

		} elsif ( $_ eq 'expanded' ) {
			# Returns class, method and function ref
			return undef if $options{full};
			$options{expanded} = 1;

		} else {
			# Unknown or unsupported options
			return undef;
		}
	}

	# Only works if the class is loaded
	return undef unless $class->loaded( $name );

	# Get the super path ( not including UNIVERSAL )
	# Rather than using Class::ISA, we'll use an inlined version
	# that implements the same basic algorithm.
	my @path  = ();
	my @queue = ( $name );
	my %seen  = ( $name => 1 );
	while ( my $cl = shift @queue ) {
		push @path, $cl;
		unshift @queue, grep { ! $seen{$_}++ }
			map { s/^::/main::/; s/\'/::/g; $_ }
			( @{"${cl}::ISA"} );
	}

	# Find and merge the function names across the entire super path.
	# Sort alphabetically and return.
	my %methods = ();
	foreach my $namespace ( @path ) {
		my @functions = grep { ! $methods{$_} }
			grep { /$RE_SYMBOL/o }
			grep { defined &{"${namespace}::$_"} } 
			keys %{"${namespace}::"};
		foreach ( @functions ) {
			$methods{$_} = $namespace;
		}
	}

	# Filter to public or private methods if needed
	my @methodlist = sort keys %methods;
	@methodlist = grep { ! /^\_/ } @methodlist if $options{public};
	@methodlist = grep { /^\_/ }   @methodlist if $options{private};

	# Return in the correct format
	@methodlist = map { "$methods{$_}::$_" } @methodlist if $options{full};
	@methodlist = map { 
		[ "$methods{$_}::$_", $methods{$_}, $_, \&{"$methods{$_}::$_"} ] 
		} @methodlist if $options{expanded};

	\@methodlist;
}





#####################################################################
# Children Related Methods

# These can go undocumented for now, until I decide if it's best to
# just search the children in namespace only, or if I should do it via
# the file system.

# Find all the loaded classes below us
sub children {
	my $class = shift;
	my $name = $class->_class(shift) or return ();

	# Find all the Foo:: elements in our symbol table
	no strict 'refs';
	map { "${name}::$_" } sort grep { s/::$// } keys %{"${name}::"};
}

# As above, but recursively
sub recursive_children {
	my $class = shift;
	my $name = $class->_class(shift) or return ();
	my @children = ( $name );

	# Do the search using a nicer, more memory efficient 
	# variant of actual recursion.
	my $i = 0;
	no strict 'refs';
	while ( my $namespace = $children[$i++] ) {
		push @children, map { "${namespace}::$_" }
			grep { ! /^::/ } # Ignore things like ::ISA::CACHE::
			grep { s/::$// }
			keys %{"${namespace}::"};
	}

	sort @children;
}





#####################################################################
# Private Methods

# Checks and expands ( if needed ) a class name
sub _class {
	my $class = shift;
	my $name = shift or return '';

	# Handle main shorthand
	return 'main' if $name eq '::';
	$name =~ s/\A::/main::/;

	# Check the class name is valid
	$name =~ /$RE_CLASS/o ? $name : '';
}

# Create a INC-specific filename, which always uses '/'
# regardless of platform.
sub _inc_filename {
	my $class = shift;
	my $name = $class->_class(shift) or return undef;
	join( '/', split /(?:'|::)/, $name ) . '.pm';
}

# Convert INC-specific file name to local file name
sub _inc_to_local {
	my $class = shift;

	# Shortcut in the Unix case
	return $_[0] if $UNIX;

	# Get the INC filename and convert
	my $inc_name = shift or return undef;
	my ($vol, $dir, $file) = File::Spec::Unix->splitpath( $inc_name );
	$dir = File::Spec->catdir( File::Spec::Unix->splitdir( $dir || "" ) );
	File::Spec->catpath( $vol, $dir, $file || "" );
}

1;

__END__

=pod

=head1 NAME

Class::Inspector - Provides information about Classes

=head1 SYNOPSIS

  use Class::Inspector;
  
  # Is a class installed and/or loaded
  Class::Inspector->installed( 'Foo::Class' );
  Class::Inspector->loaded( 'Foo::Class' );
  
  # Filename related information
  Class::Inspector->filename( 'Foo::Class' );
  Class::Inspector->resolved_filename( 'Foo::Class' );
  
  # Get subroutine related information
  Class::Inspector->functions( 'Foo::Class' );
  Class::Inspector->function_refs( 'Foo::Class' );
  Class::Inspector->function_exists( 'Foo::Class', 'bar' );
  Class::Inspector->methods( 'Foo::Class', 'full', 'public' );

=head1 DESCRIPTION

Class::Inspector allows you to get information about a loaded class. Most or
all of this information can be found in other ways, but they arn't always
very friendly, and usually involve a relatively high level of Perl wizardry,
or strange and unusual looking code. Class::Inspector attempts to provide 
an easier, more friendly interface to this information.

=head1 METHODS

=head2 installed $class

Tries to determine if a class is installed on the machine, or at least 
available to Perl. It does this by essentially wrapping around 
C<resolved_filename>. Returns true if installed/available, returns 0 if
the class is not installed. Returns undef if the class name is invalid.

=head2 loaded $class

Tries to determine if a class is loaded by looking for symbol table entries.
This method will work even if the class does not have it's own file, but is
contained inside a single file with multiple classes in it. Even in the
case of some sort of run-time loading class being used, these typically
leave some trace in the symbol table, so an C<Autoload> or C<Class::Autouse>
based class should correctly appear loaded.

=head2 filename $class

For a given class, returns the base filename for the class. This will NOT be
a fully resolved filename, just the part of the filename BELOW the @INC entry.

For example: Class->filename( 'Foo::Bar' ) returns 'Foo/Bar.pm'

This filename will be returned for the current platform. It should work on all
platforms. Returns the filename on success. Returns undef on error, which could
only really be caused by an invalid class name.

=head2 resolved_filename $class, @try_first

For a given class, returns the fully resolved filename for a class. That is, the
file that the class would be loaded from. This is not nescesarily the file that
the class WAS loaded from, as the value returned is determined each time it runs,
and the @INC include path may change. To get the actual file for a loaded class,
see the C<loaded_filename> method. Returns the filename for the class on success. 
Returns undef on error.

=head2 loaded_filename $class

For a given, loaded, class, returns the name of the file that it was originally
loaded from. Returns false if the class is not loaded, or did not have it's own
file.

=head2 functions $class

Returns a list of the names of all the functions in the classes immediate
namespace. Note that this is not the METHODS of the class, just the functions.
Returns a reference to an array of the function names on success. Returns undef
on error or if the class is not loaded.

=head2 function_refs $class

Returns a list of references to all the functions in the classes immediate
namespace. Returns a reference to an array of CODE refs of the functions on
success. Returns undef on error or if the class is not loaded.

=head2 function_exists $class, $function

Given a class and function the C<function_exists> method will check to see
if the function exists in the class. Note that this is as a function, not
as a method. To see if a method exists for a class, use the C<can> method
in UNIVERSAL, and hence to every other class. Returns 1 if the function
exists. Returns 0 if the function does not exist. Returns undef on error,
or if the class is not loaded.

=head2 methods $class, @options

For a given class name, the C<methods> method will returns ALL the methods
available to that class. This includes all methods available from every
class up the class' C<@ISA> tree. Returns a reference to an array of the
names of all the available methods on success. Returns undef if the class
is not loaded.

A number of options are available to the C<methods> method. These should
be listed after the class name, in any order.

=over 4

=item public

The C<public> option will return only 'public' methods, as defined by the Perl
convention of prepending an underscore to any 'private' methods. The C<public> 
option will effectively remove any methods that start with an underscore.

=item private

The C<private> options will return only 'private' methods, as defined by the
Perl convention of prepending an underscore to an private methods. The
C<private> option will effectively remove an method that do not start with an
underscore.

B<Note: The C<public> and C<private> options are mutually exclusive>

=item full

C<methods> normally returns just the method name. Supplying the C<full> option
will cause the methods to be returned as the full names. That is, instead of
returning C<[ 'method1', 'method2', 'method3' ]>, you would instead get
C<[ 'Class::method1', 'AnotherClass::method2', 'Class::method3' ]>.

=item expanded

The C<expanded> option will cause a lot more information about method to be 
returned. Instead of just the method name, you will instead get an array
reference containing the method name as a single combined name, ala C<full>,
the seperate class and method, and a CODE ref to the actual function ( if
available ). Please note that the function reference is not guarenteed to 
be available. C<Class::Inspector> is intended at some later time, work 
with modules that have some some of common run-time loader in place ( e.g
C<Autoloader> or C<Class::Autouse> for example.

The response from C<methods( 'Class', 'expanded' )> would look something like
the following.

  [
    [ 'Class::method1',   'Class',   'method1', \&Class::method1   ],
    [ 'Another::method2', 'Another', 'method2', \&Another::method2 ],
    [ 'Foo::bar',         'Foo',     'bar',     \&Foo::bar         ],
  ]

=back

=head1 BUGS

No known bugs, but I'm taking suggestions for additional functionality.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker

  http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class%3A%3AInspector

For other issues, contact the author

=head1 AUTHOR

        Adam Kennedy
        cpan@ali.as
        http://ali.as/

=head1 SEE ALSO

L<Class::Handle>, which wraps this one

=head1 COPYRIGHT

Copyright (c) 2002 - 2004 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
