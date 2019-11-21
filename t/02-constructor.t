#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Minecraft::RCON;
use Local::Helpers;
use Test::Warnings ':all';
use Test::More;

my $rcon;

ok $rcon = Minecraft::RCON->new, 'No options';
ok $rcon = Minecraft::RCON->new({ password => 'secret' }), 'Synopsis';
ok $rcon = Minecraft::RCON->new(  password => 'secret'  ), 'Not a HASH ref';

like(warning { Minecraft::RCON->new({foo => 'bar'}) },
    qr/^\QIgnoring unknown\E/, 'Unknown option');

done_testing;
