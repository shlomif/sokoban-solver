#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Shlomif::Sokoban::Solver' );
}

diag( "Testing Shlomif::Sokoban::Solver $Shlomif::Sokoban::Solver::VERSION, Perl $], $^X" );
