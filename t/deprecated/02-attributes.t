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

my $rcon = Minecraft::RCON->new(
    color_mode  => 'ignore',
    password    => 'secret',
);
my $r;

like(warning { $r = $rcon->convert_color }, qr/^convert_color.. is deprecated/);
ok !$r, 'We are not converting color';
like(warning { $rcon->convert_color(1) }, qr/^convert_color.. is deprecated/);
is $rcon->color_mode, 'convert', 'We are really converting color';

like(warning { $r = $rcon->strip_color }, qr/^strip_color.. is deprecated/);
ok !$r, 'We are not stripping color';
like(warning { $rcon->strip_color(1) }, qr/^strip_color.. is deprecated/);
is $rcon->color_mode, 'strip', 'We are really stripping color';

like(warning { $r = $rcon->address }, qr/^address.. is deprecated/);
is $r, '127.0.0.1', 'address works';
like(warning { $r = $rcon->address('localhost') }, qr/^address.. is deprecated/);
is $rcon->{address}, 'localhost', 'address changed';

like(warning { $r = $rcon->port }, qr/^port.. is deprecated/);
is $r, 25575, 'port works';
like(warning { $rcon->port(1234) }, qr/^port.. is deprecated/);
is $rcon->{port}, 1234, 'port changed';

like(warning { $r = $rcon->password }, qr/^password.. is deprecated/);
is $r, 'secret', 'password works';
like(warning { $rcon->password('VERY secret') }, qr/^password.. is deprecated/);
is $rcon->{password}, 'VERY secret', 'password changed';

done_testing
