use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Shlomif::Sokoban::Solver',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@iglu.org.il>',
    dist_version_from   => 'lib/Shlomif/Sokoban/Solver.pm',
    build_requires => {
        'Test::More' => 0,
        'Class::XSAccessor' => 0,
    },
    add_to_cleanup      => [ 'Shlomif-Sokoban-Solver-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
