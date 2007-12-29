package Shlomif::Sokoban::Solver::Board;

use strict;
use warnings;

=head1 NAME

Shlomif::Sokoban::Solver::Board - a board for the sokosolver.

=head1 SYNOPSIS

For internal use by the Sokoban solver. See the test files.

=cut

use List::Util qw(max);

use Object::Tiny qw/
    height
    width
/;

sub load
{
    my ($pkg, $contents) = @_;

    # Remove trailing whitespace.
    $contents =~ s{(\s*\n)+\z}{}ms; 

    # Remove trailing whitespace from lines.
    $contents =~ s{\s+$}{}gms;

    my @lines = (map { [ split(//, $_) ] } split(/\n/, $contents));

    my $self = 
        $pkg->new(
            height => scalar(@lines),
            width => max(map { scalar(@$_) } @lines),
        );

    return $self;
}

=head1 METHODS

=head2 width()

Returns the width of the board.

=head2 height()

Returns the height of the board.

=head2 load($board)

Loads a board in standard Sokoban notation.

=cut

1;

