#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib qw<t/lib>;
use Test::Exception;
use Test::More;
use Local::Helpers;
use Minecraft::RCON;
use Test::Warnings ':all';

my $rcon;

like(warning { Minecraft::RCON->new(strip_color => 1) }, 
    qr/strip_color deprecated/);

like(warning { Minecraft::RCON->new(convert_color => 1) }, 
    qr/convert_color deprecated/);

done_testing;
