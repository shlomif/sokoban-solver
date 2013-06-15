use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Games::Sokoban::Solver',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@iglu.org.il>',
    dist_version_from   => 'lib/Games/Sokoban/Solver.pm',
    configure_requires => {
        'Module::Build' => '0.36',
    },
    requires => {
        'Class::XSAccessor' => 0,
        'List::Util' => 0,
        'strict' => 0,
        'warnings' => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Games-Sokoban-Solver-*' ],
    meta_merge =>
    {
        resources =>
        {
            repository => "http://bitbucket.org/shlomif/sokoban-solver",
        },
        keywords =>
        [
            "sokoban",
            "solver",
        ],
    },

);

$builder->create_build_script();
