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
    _data
    _dests
/;

my $dest_place_bits = 0x1;
my $wall_bits = 0x2;

=head1 METHODS

=head2 load($board)

Loads a board in standard Sokoban notation.

=cut

sub load
{
    my ($pkg, $contents) = @_;

    # Remove trailing whitespace.
    $contents =~ s{(\s*\n)+\z}{}ms; 

    # Remove trailing whitespace from lines.
    $contents =~ s{\s+$}{}gms;

    my @lines = (map { [ split(//, $_) ] } split(/\n/, $contents));

    my $data = "";

    my $self = 
        $pkg->new(
            height => scalar(@lines),
            width => max(map { scalar(@$_) } @lines),
            _data => \$data,
            _dests => [],
        );

    foreach my $y (0 .. $#lines)
    {
        my $l = $lines[$y];
        foreach my $x (0 .. $#$l)
        {
            my $offset = $y*$self->width()+$x;
            if ($l->[$x] eq "#")
            {
                vec(${$self->_data()}, $offset, 2) = $wall_bits;
            }
            elsif ($l->[$x] eq ".")
            {
                vec(${$self->_data()}, $offset, 2) = $dest_place_bits;
                push @{$self->_dests()}, [$x, $y];
            }
            else
            {
                vec(${$self->_data()}, $offset, 2) = 0;
            }
        }
    }

    return $self;
}

=head2 $board->is_wall($x,$y)

Returns if the block at the position $x,$y is a wall.

=cut

sub is_wall
{
    my ($self, $x, $y) = @_;

    return (vec(${$self->_data()}, $y*$self->width()+$x, 2) == $wall_bits);
}

=head2 $board->is_dest($x,$y)

Returns if the block at the position $x,$y is a destination block.

=cut

sub is_dest
{
    my ($self, $x, $y) = @_;

    return (vec(${$self->_data()}, $y*$self->width()+$x, 2)
            == $dest_place_bits
        );
}


=head2 width()

Returns the width of the board.

=head2 height()

Returns the height of the board.

=cut

1;

