#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Games::Sokoban::Solver' );
}

diag( "Testing Games::Sokoban::Solver $Games::Sokoban::Solver::VERSION, Perl $], $^X" );
