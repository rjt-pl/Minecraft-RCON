#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::Exception;
use Test::More;
use Local::Helpers;

use Minecraft::RCON;

# We're testing $rcon->command(), not a bunch of Minecraft commands.

# Return command response from server
sub cmd($@) {
    my $cmd = shift;
    my ($rcon, $mock, $_mock) = rcon_mock({password => 'secret'});
    disp_add($_mock, @$_) for @_;
    disp_add($_mock, qr/\d+:\d+:nonce$/ => sub {
        my ($id, $type, $payload, %p) = @_;
        [ $id, RESPONSE_VALUE, sprintf("Unknown request %x", $type) ]
    });
    ok $rcon->connect, 'Connects before ' . $cmd;

    my $r = eval { $rcon->command($cmd); };
    $rcon->disconnect;

    $r;
}

# Make random junk of specified length
sub junk { join '', map { chr(rand(26) + ord('a')) } 1..$_[0] }

is cmd('help', [ '2:2:help' => [2, RESPONSE_VALUE, 'help!' ]]), 'help!', 'Basic command';
is cmd('', [ '2:2:' => [2, RESPONSE_VALUE ,'ERROR']]), undef, 'Blank command';

# Various fragmentation sizes, including boundary cases
for (qw/80 1024 4095 4096 4097 10240/) {
    my $junk = junk($_);
    is cmd('junk', [ '2:2:junk' => [2, RESPONSE_VALUE, $junk] ]), $junk, "Frag:$_";
}

{
    my $rcon = Minecraft::RCON->new({password => 'secret'});
    throws_ok { $rcon->command('foo') } qr/Not connected/;
    $rcon->disconnect;
}

done_testing;
