#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::More;

use Minecraft::RCON;

# Ensure that we don't export anything unless asked
# Positive version of these tests is handled in xx-color.t

is eval("COLOR_$_"), undef, "COLOR_$_ not imported" for qw<IGNORE CONVERT STRIP>;

done_testing;
