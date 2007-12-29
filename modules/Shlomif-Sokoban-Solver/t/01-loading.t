use strict;
use warnings;

use Test::More tests => 13;

use Shlomif::Sokoban::Solver::Board;

my $board_contents = <<'EOF';
  ####
  #  #
  #  ####
###$.$  #
#  .@.  #
#  $.$###
####  #
   #  #
   ####
EOF

{
    my $board = Shlomif::Sokoban::Solver::Board->load($board_contents);

    # TEST
    is ($board->width(), 9, "Testing the board width");
    # TEST
    is ($board->height(), 9, "Testing the board height");

    # TEST
    ok ($board->is_wall(2, 0), "Testing if 2,0 is a wall");
    # TEST
    ok ($board->is_wall(3, 0), "3,0 is a wall");
    # TEST
    ok ($board->is_wall(5, 0), "5,0 is a wall");
    # TEST
    ok (!$board->is_wall(6, 0), "6,0 is not a wall");
    # TEST
    ok (!$board->is_wall(3, 1), "3,1 is not a wall");
    # TEST
    ok ($board->is_wall(2, 3), "2,3 is a wall");
    # TEST
    ok ($board->is_wall(7, 5), "7,5 is a wall");
    # TEST
    ok (!$board->is_wall(4, 7), "4,7 is not a wall");
    # TEST
    ok ($board->is_dest(4, 3), "4,7 is a dest");
    # TEST
    ok (!$board->is_wall(4, 3), "4,3 (which is a dest) is not a wall");
    # TEST
    is_deeply($board->_dests(),
        [[4,3], [3,4], [5,4], [4,5]],
    );
}
