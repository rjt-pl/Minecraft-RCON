#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN { 
    use_ok('Minecraft::RCON') 
        or BAIL_OUT('use failed. No point continuing.');
}

diag "Testing Minecraft::RCON $Minecraft::RCON::VERSION, Perl $]";
