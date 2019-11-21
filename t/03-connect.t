#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::Exception;
use Test::More;
use Test::Warnings ':all';
use Local::Helpers;
use Carp; # for mocked subs

use Minecraft::RCON;

my $rcon = Minecraft::RCON->new;

throws_ok { $rcon->connect } qr/Password required/;

{
    my ($rcon, $mock, $_mock) = rcon_mock({password => 'secret'}, { 
        new => sub { $! = 111; return }
    });
    is ref($rcon), 'Minecraft::RCON';
    throws_ok { $rcon->connect } qr/Connection.*?failed/, 'Connection failed';
}

my ($mock, $_mock);
($rcon, $mock, $_mock) = rcon_mock({password => 'secret'});
ok $rcon->connect, 'Connects';

($rcon, $mock, $_mock) = rcon_mock({password => 'wrong'});
disp_add($_mock, '1:3:wrong'  => sub { [-1, 2, ''] });
throws_ok { $rcon->connect } qr/^\QRCON authentication failed\E/;

($rcon, $mock, $_mock) = rcon_mock({password => 'fluffy'});
disp_add($_mock, '1:3:fluffy' => sub { [31, 2, ''] });
throws_ok { $rcon->connect } qr/\QExpected ID\E/;

($rcon, $mock, $_mock) = rcon_mock({password => 'fluffy'});
disp_add($_mock, '1:3:fluffy' => sub { [ 1, 3, ''] });
throws_ok { $rcon->connect } qr/^\QExpected AUTH_RESPONSE\E/;

($rcon, $mock, $_mock) = rcon_mock({password => 'fluffy'});
disp_add($_mock, '1:3:fluffy' => sub { [1, 2, 'Not Blank'] });
throws_ok { $rcon->connect } qr/^\QNon-blank payload <Not Blank>\E/;

($rcon, $mock, $_mock) = rcon_mock({password => 'secret'});
ok $rcon->connect, 'Connects';
ok $rcon->disconnect, 'Disconnects';
ok $rcon->disconnect, 'Disconnects twice ok';

($rcon, $mock, $_mock) = rcon_mock({password => 'secret'});
ok $rcon->disconnect, 'Disconnect without connect ok';

($rcon, $mock, $_mock) = rcon_mock({password => 'secret'});
ok !$rcon->connected, 'Not connected yet';
$rcon->connect;
ok  $rcon->connected, 'Now we are connected';
$rcon->disconnect;
ok !$rcon->connected, 'Disconnected again';

done_testing;
