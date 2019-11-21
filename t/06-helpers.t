#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::Exception;
use Test::More;
use Local::Helpers;

use Minecraft::RCON;

{
    my $rcon = Minecraft::RCON->new;
    my $next_id = $rcon->_next_id;

    is $rcon->_next_id, ++$next_id, 'next_id increments';
    is $rcon->_next_id, ++$next_id, 'next_id increments twice';

    $rcon->{request_id} = 2**31-2;
    is $rcon->_next_id, 2**31-1, 'next_id hits limit';
    is $rcon->_next_id, 0, 'next_id rolls over at limit';
}

{
    my ($rcon, $mock, $_mock) = rcon_mock({password => 'secret'});
    $rcon->connect;
    my $next_id = $rcon->_next_id;
    is $next_id, 2, 'Correct initial _next_id';
    $next_id = $rcon->_next_id;
    is $next_id, 3, 'Actual command will use 4';

    disp_add($_mock, '4:2:help' => sub { [4, RESPONSE_VALUE, "Your help"] });
    disp_add($_mock, qr/^\d+:\d+:nonce$/, => sub {
        my ($id, $type, $payload, %p) = @_; 
        [ $id, RESPONSE_VALUE, sprintf("Unknown request %x", $type) ]
    });
    
    #packet_trace { $rcon->command('help') } 'help command';
    $rcon->command('help');

    is $rcon->_next_id, 5, 
        'next_id increments on command but not on nonce';
}

done_testing;
