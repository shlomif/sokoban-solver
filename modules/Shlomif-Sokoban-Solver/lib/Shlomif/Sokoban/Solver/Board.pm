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
    _init_state
/;

my $dest_place_bits = 0x1;
my $wall_bits = 0x2;

my $box_bits = 0x1;
my $reachable_bits = 0x2;

=head1 METHODS

=head2 load($board)

Loads a board in standard Sokoban notation.

=cut

sub _calc_offset
{
    my ($self, $x, $y) = @_;

    return $y*$self->width()+$x;
}

sub load
{
    my ($pkg, $contents) = @_;

    # Remove trailing whitespace.
    $contents =~ s{(\s*\n)+\z}{}ms; 

    # Remove trailing whitespace from lines.
    $contents =~ s{\s+$}{}gms;

    my @lines = (map { [ split(//, $_) ] } split(/\n/, $contents));

    my $data = "";

    my $init_state = "";
    my $init_pos;

    my $self = 
        $pkg->new(
            height => scalar(@lines),
            width => max(map { scalar(@$_) } @lines),
            _data => \$data,
            _dests => [],
            _init_state => \$init_state,
        );



    foreach my $y (0 .. $#lines)
    {
        my $l = $lines[$y];

        foreach my $x (0 .. $#$l)
        {
            my $offset = $self->_calc_offset($x, $y);

            # Initialise the init_state block to the default.
            vec($init_state, $offset, 2) = 0;
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
                if ($l->[$x] eq '$')
                {
                    vec($init_state, $offset, 2) = $box_bits;
                }
                elsif ($l->[$x] eq '@')
                {
                    $init_pos = [$x, $y];
                }
            }
        }
    }

    if (!defined($init_pos))
    {
        die "The initial position of the player was not defined.";
    }

    $self->_mark_reachable(\$init_state, @$init_pos);

    return $self;
}

=head2 $board->is_wall($x,$y)

Returns if the block at the position $x,$y is a wall.

=cut

sub is_wall
{
    my ($self, $x, $y) = @_;

    return (vec(${$self->_data()}, $self->_calc_offset($x,$y), 2) == $wall_bits);
}

=head2 $board->is_dest($x,$y)

Returns if the block at the position $x,$y is a destination block.

=cut

sub is_dest
{
    my ($self, $x, $y) = @_;

    return (vec(${$self->_data()}, $self->_calc_offset($x,$y), 2)
            == $dest_place_bits
        );
}

=head2 $board->is_box($s_ref, $x, $y)

Is ($x,$y) in the state referenced by $s_ref a box?

=cut

sub is_box
{
    my ($self, $s_ref, $x, $y) = @_;
    return (vec($$s_ref, $self->_calc_offset($x,$y), 2) == $box_bits);
}

=head2 $board->is_reachable($s_ref, $x, $y)

Is ($x,$y) in the state referenced by $s_ref reachable by the player?

=cut

sub is_reachable
{
    my ($self, $s_ref, $x, $y) = @_;
    return (vec($$s_ref, $self->_calc_offset($x,$y), 2) == $reachable_bits);
}

sub _mark_reachable
{
    my ($self, $s_ref, $start_x, $start_y) = @_;

    # Breadth-first search to find all the reachable positions in the board.
    my @to_check =([$start_x, $start_y]);

    while (my $pos = shift(@to_check))
    {
        # Mark as reachable.
        vec($$s_ref, $self->_calc_offset(@$pos), 2) = $reachable_bits;

        foreach my $offset ([-1,0],[1,0],[0,-1],[0,1])
        {
            my @new_pos = ($pos->[0]+$offset->[0], $pos->[1]+$offset->[1]);
            if (   ($new_pos[0] >= 0)
                && ($new_pos[1] >= 0)
                && ($new_pos[0] < $self->width())
                && ($new_pos[1] < $self->height())
                && (! $self->is_wall(@new_pos))
                && (! $self->is_box($s_ref, @new_pos))
                && (! $self->is_reachable($s_ref, @new_pos))
               )
            {
                push @to_check, \@new_pos;
            }
        }
    }

    return;
}

sub _rotate
{
    my ($self, $s_ref) = @_;

    my $ret = "";

    my $width = $self->width()-1;
    my $height = $self->height()-1;

    for my $x (0 .. $width)
    {
        for my $y (0 .. $height)
        {
            vec($ret, $self->_calc_offset($y, $width-$x), 2) =
                vec($$s_ref, $self->_calc_offset($x,$y), 2);
        }
    }

    return \$ret;
}

=head2 width()

Returns the width of the board.

=head2 height()

Returns the height of the board.

=cut

1;

