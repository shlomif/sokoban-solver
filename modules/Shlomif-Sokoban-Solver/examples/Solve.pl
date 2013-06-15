use strict;
use warnings;

use Games::Sokoban::Solver;

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
    my $board = Games::Sokoban::Solver->load($board_contents);

    $board->solve();
}
