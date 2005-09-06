use inc::Module::Install;

name          ( 'Class-Inspector'              );
abstract      ( 'Get information about a class and its structure' );
author        ( 'Adam Kennedy <cpan@ali.as>' );
version_from  ( 'lib/Class/Inspector.pm'     );
requires      ( 'perl'            => '5.005' );
requires      ( 'File::Spec'      => '0.80'  );
build_requires( 'Test::More'      => '0.47'  );
auto_install  (                              );

&WriteAll;
