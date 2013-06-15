use strict;
use warnings;

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

    $board->solve();
}
