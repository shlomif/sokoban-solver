package Games::Sokoban::Solver;

use strict;
use warnings;

=head1 NAME

Games::Sokoban::Solver - a board for the sokosolver.

=head1 SYNOPSIS

For internal use by the Sokoban solver. See the test files.

=cut

our $VERSION = '0.0.1';

use List::Util qw(max);

use Class::XSAccessor
    accessors =>
    {
        map { $_ => $_ }
        qw/
        height
        width
        _collect
        _data
        _dests
        _init_state
        _queue
        /
    },
    constructor => 'new'
    ;

my $dest_place_bits = 0x1;
my $wall_bits = 0x2;

my $box_bits = 0x1;
my $reachable_bits = 0x2;

=head1 METHODS

=head2 new(...)

The internal constructor - for internal use - see ->load() instead.

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
            _collect => +{},
            _queue => [],
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

# Get the minimal rotation permutation
sub _get_min_rot_perm
{
    my ($self, $s_ref) = @_;

    # Find the minimal board by its rotation permutations.
    my $min_rot_times = 0;
    my $min_rot_board = $s_ref;
    foreach my $r (1 .. 3)
    {
        my $new = $self->_rotate($s_ref);
        if ($$new lt $$min_rot_board)
        {
            $min_rot_times = $r;
            $min_rot_board = $new;
        }
        $s_ref = $new;
    }

    return ($min_rot_times, $min_rot_board);
}

sub _derive
{
    my ($self, $state_ref, $box_xy, $push_to_xy) = @_;

    my $new_state = "";

    for my $y (0 .. $self->height()-1)
    {
        for my $x (0 .. $self->width()-1)
        {
            my $offset = $self->_calc_offset($x, $y);
            if ($self->is_box($state_ref, $x, $y))
            {
                vec($new_state, $offset, 2) = $box_bits;
            }
            else
            {
                vec($new_state, $offset, 2) = 0;
            }
        }
    }

    # Move the new box.
    vec($new_state, $self->_calc_offset(@$box_xy), 2) = 0;
    vec($new_state, $self->_calc_offset(@$push_to_xy), 2) = $box_bits;

    # Mark the reachable bits.
    $self->_mark_reachable(\$new_state, @$box_xy);

    return \$new_state;
}

sub _output
{
    my ($self, $s_ref) = @_;

    for my $y (0 .. ($self->height()-1))
    {
        for my $x (0 .. ($self->width()-1))
        {
            print   $self->is_wall($x, $y) ? "#"
                  : $self->is_box($s_ref, $x, $y)  ? '$'
                  : $self->is_dest($x, $y) ? "."
                  : " "
                  ;
        }
        print "\n";
    }
    print "\n";
}

sub _is_final
{
    my ($self, $s_ref) = @_;

    foreach my $d (@{$self->_dests()})
    {
        if (! $self->is_box($s_ref, @$d))
        {
            return 0;
        }
    }
    return 1;
}

sub _try_to_move_box
{
    my ($self, $state_ref, $x, $y) = @_;

    for my $offset ([-1,0],[1,0],[0,-1],[0,1])
    {
        my @push_to = ($x+$offset->[0], $y+$offset->[1]);
        my @push_from = ($x-$offset->[0], $y-$offset->[1]);

        if (   (! $self->is_wall(@push_to))
            && (! $self->is_box($state_ref, @push_to))
            && $self->is_reachable($state_ref, @push_from)
           )
        {
            # We can push.
            my $new_state_ref =
                $self->_derive($state_ref, [$x, $y], \@push_to)
                ;

            # Print it - this is temporary for debugging.
            # (Now commented out.)
            # $self->_output($new_state_ref);

            # Else - register it and proceed.

            my ($rot_idx, $rot_state) =
                $self->_get_min_rot_perm($new_state_ref);
            if (exists($self->_collect()->{$$rot_state}))
            {
                # Do nothing
            }
            else
            {
                $self->_collect()->{$$rot_state} =
                {
                    r => (($rot_idx+$self->_collect()->{$$state_ref}->{r})%4),
                    p => $state_ref
                };
                if ($self->_is_final($rot_state))
                {
                    return $rot_state;
                }
                push @{$self->_queue()}, $rot_state;
            }

        }
    }

    return;
}

sub _trace_solution
{
    my ($self, $final_state) = @_;

    my @solution;

    {
        my $state = $final_state;

        while (defined($state))
        {
            push @solution, $state;
            $state = $self->_collect->{$$state}->{p};
        }
    }

    foreach my $state (reverse(@solution))
    {
        my $r = $self->_collect->{$$state}->{r};

        # Normalize the state from its rotated position.
        my $rot_state = $state;
        while ($r%4 != 0)
        {
            $rot_state = $self->_rotate($rot_state);
            $r++;
        }

        $self->_output($rot_state);
    }
}

=head2 $board->solve()

Actually solve the board.

=cut

sub solve
{
    my $self = shift;

    my $s_ref = $self->_init_state();

    my ($rot_idx, $rot_state) = $self->_get_min_rot_perm($s_ref);

    $self->_collect()->{$$rot_state} = { r => $rot_idx, p => undef() };

    push @{$self->_queue()}, $rot_state;

    my $w = $self->width()-1;
    my $h = $self->height()-1;

    while (my $state_ref = pop(@{$self->_queue()}))
    {
        for my $y (0 .. $h)
        {
            for my $x (0 .. $w)
            {
                if ($self->is_box($state_ref, $x, $y))
                {
                    my $final = $self->_try_to_move_box($state_ref, $x, $y);

                    if (defined($final))
                    {
                        $self->_trace_solution($final);

                        return $final;
                    }
                }
            }
        }
    }
}

=head2 width()

Returns the width of the board.

=head2 height()

Returns the height of the board.

=cut

1;

