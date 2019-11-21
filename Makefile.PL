use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME                => 'Minecraft::RCON',
    AUTHOR              => [q{Ryan Thompson <rjt@cpan.org>},
                            q{Frederik Vold <demmy@cpan.org>}],
    VERSION_FROM        => 'lib/Minecraft/RCON.pm',
    ABSTRACT_FROM       => 'lib/Minecraft/RCON.pm',
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => '5.008',
    CONFIGURE_REQUIRES  => { 'ExtUtils::MakeMaker' => 0, },
    EXE_FILES           => [ qw< bin/mcrcon.pl bin/mcrcon > ],

    MIN_PERL_VERSION    => 5.008,
    TEST_REQUIRES       => { 'Test::Exception'  => 0,
                             'Test::More'       => 0,
                             'Test::Output'     => 0,
                             'Test::Warnings'   => 0.02,},

    PREREQ_PM           => { 'Carp'             => 0,
                             'IO::Socket'       => 1.18,
                             'Term::ANSIColor'  => 3.02 },

    META_MERGE          => {
        resources => {
            'meta-spec' => { version => 2 },
            repository  => 'https://github.com/rjt-pl/Minecraft::RCON.git',
        },
    },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',           },
    clean     => { FILES    => 'Minecraft-RCON-*'                    },
    test      => { TESTS    => 't/*.t t/deprecated/*.t t/bin/*.t'    },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
    my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
