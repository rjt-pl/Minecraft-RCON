#!perl -T

# t/lib/helpers.pl - Test framework shared code for Minecraft::RCON

package Local::Helpers;

use 5.010;
use strict;
use warnings;
use Test::Exception;
use Test::More;
use Test::Output;
use Test::MockModule;
use Test::Warnings ':all';
use Carp;
use List::Util qw/min max any/;
use IO::Socket 1.18;

use Exporter 'import';
our @EXPORT = qw(packet_trace_on packet_trace_off packet_trace
                 rcon_mock disp_add debug_packet dep_re warns_like
                 COMMAND AUTH AUTH_RESPONSE AUTH_FAIL RESPONSE_VALUE );

use constant {
    # Packet types
    COMMAND         => 2,           # Command packet type
    AUTH            => 3,           # Minecraft RCON login packet type
    AUTH_RESPONSE   => 2,           # Server auth response
    AUTH_FAIL       =>-1,           # Auth failure (password invalid)
    RESPONSE_VALUE  => 0,           # Server response
};

# Prototypes needed for calls within this source file.
sub _printable($);

# Deprecated regexp
sub dep_re() { qr/\Qdeprecated and will be removed in a future release.\E/ }

# Packet trace - Outputs all packets as diag() messages
my $TRACE = 0;
sub packet_trace_on()  { $TRACE = 1 }
sub packet_trace_off() { $TRACE = 0 }
sub packet_trace(&;$)    {
    my $old_TRACE = $TRACE;
    $TRACE = 1;
    diag "Packet trace: $_[1]" if defined $_[1];
    $_[0]->();
    $TRACE = $old_TRACE;
}

# Dispatch table for default (but still mocked) methods
my %default_mock = (
    shutdown     => sub { $_[0]->{_mock}{connected} = 0 },
    connected    => sub { $_[0]->{_mock}{connected} },
    send         => \&mock_send,
    recv         => \&mock_recv,
    recv_buf     => '',
    _mock_push   => \&_mock_push,
    _disp_find   => \&_disp_find,
    _disp_dump   => \&_disp_dump,
);

# Generate a Minecraft::RCON object that calls connect with a mocked
# IO::Socket::INET object. Be sure to use dies_ok { } if you're expecting
# this to fail. First argument is a hashref of RCON constructor args.
# Second argument is a hashref of IO::Socket::INET mocked subs.
sub rcon_mock {
    my ($rcon_args, $mocks) = @_;
    $mocks = { } if not defined $mocks;

    my $mock = Test::MockModule->new('IO::Socket::INET');

    my $_mock = {
        recv_dispatch   => [ ],
        recv_buf        => '',
        connected       => 1,
    };

    my %mocks = ( %default_mock,
                  new => sub {
                    shift; bless { @_, _mock => $_mock }, 'IO::Socket::INET';
                  },
                  %$mocks );

    disp_add($_mock, '1:3:secret' => sub { [1, AUTH_RESPONSE, ''] });
    $mock->mock($_ => $mocks{$_}) for keys %mocks;

    return Minecraft::RCON->new($rcon_args), $mock, $_mock;
}

# Install an entry into the recv_dispatch. See _disp_find for details.
sub disp_add {
    my ($_mock, $check, $respond, $priority) = @_;
    $priority = 1 if not defined $priority;
    push @{$_mock->{recv_dispatch}}, [ $check, $respond, $priority ];
}

# Find an entry in the recv_dispatch
sub _disp_find {
    my ($s, $id, $type, $payload) = @_;

    my %r; # Responses, by priority
    for (@{$s->{_mock}{recv_dispatch}}) {
        my ($check, $resp, $pri) = @$_;
        $pri = 0 if not defined $pri;
        my %info; # Any potential info extracted from check phase

        # $check phase. Skip this iteration if not a match
        if ('CODE' eq ref $check) {
            %info = $check->($id, $type, $payload);
            next unless scalar keys %info;
        }
        elsif ('Regexp' eq ref $check) {
            next unless "$id:$type:$payload" =~ /$check/;
            %info = %+;
        }
        elsif ('' eq ref $check) {
            next unless "$id:$type:$payload" eq $check;
        } else {
            croak "Expecting CODE, Regexp or scalar, got " . ref $check
        }

        # $resp can be either an array ref [ $id, $type, $payload ]
        # or a code ref that takes $id, $type, $payload, %info and
        # returns an array ref [ $id, $type, $payload ]
        $r{$pri} = $resp->($id, $type, $payload, %info) if 'CODE' eq ref $resp;
        $r{$pri} = $resp if 'ARRAY' eq ref $resp;
    }

    # Croak if nothing found. (Install a default that always matches, if this
    # is undesirable).
    $s->_disp_dump("Don't know how to respond to <$id:$type:$payload>") unless %r;

    # Now take the highest priority response and package that up.
    my $result = $r{ max keys %r };
}

# Dump the dispatch table (uses diag)
sub _disp_dump {
    my ($s, $err) = @_;

    diag "Dispatch table:";
    my $len = min 40, max map { length $_->[0] } @{$s->{_mock}{recv_dispatch}};

    for (@{$s->{_mock}{recv_dispatch}}) {
        my ($call, $resp) = @$_;
        $resp = 'sub { ... }' if 'CODE' eq ref $resp;
        diag sprintf("  %${len}s => %s", $call, $resp);
    }

    croak $err if $err;
}

# Mock send by looking at the packet received, pulling it apart, and
# barfing if it is malformed in any way. If it is OK, then we look at
# the recv_dispatch table and put the appropriate response on the
# recv_buf
sub mock_send {
    my ($s, $pkt) = @_;

    debug_packet(send => $pkt);
    my ($size, $id, $type, $text) = _decode_packet($pkt);

    $s->_mock_push(@{$s->_disp_find($id, $type, $text)});

    return 1;
}

# Push a response onto the receive buffer. Normally called by mock_send.
# This will be put into the appropriate RCON packet format automatically
# **and will be fragmented if the payload length exceeds 4096.** Submit
# payloads of 4095 bytes or less to avoid fragmentation.
sub _mock_push {
    my ($s, $id, $type, $payload) = @_;

    if (length $payload > 4096) {
        $s->_mock_push($id, $type, substr($payload, 0, 4096));
        $s->_mock_push($id, $type, substr($payload, 4096));
        return;
    }
    my $pkt = pack('V!V' => $id, $type) . $payload . "\0\0";
    my ($len_pack) = (pack V => length($pkt));
    croak "len_pack <$len_pack> is not a valid length" unless 4 == length $len_pack;
    debug_packet($len_pack . $pkt);
    $s->{_mock}{recv_buf} .= $len_pack . $pkt;
}

# Convert a string to printable ASCII
sub _printable($) {
    local $_ = shift;

    s/\0/\\0/g;
    s/([^ -~])/'\x'.sprintf('%02x', ord($1))/eg;

    $_
}

# Mock recv by pulling from the recv_buf created by mock_send.
# Basic error handling if we are not connected or the buf
# is empty. (Instead of blocking, we croak())
sub mock_recv {
    my ($s, undef, $len) = @_;

    croak "Not connected" unless $s->connected;
    confess "Buffer not defined" if not exists $s->{_mock}{recv_buf};
    croak "recv() would block" if 0 == length $s->{_mock}{recv_buf};

    my $buf  = substr $s->{_mock}{recv_buf}, 0, $len;
    my $rest = substr $s->{_mock}{recv_buf}, $len;
    $s->{_mock}{recv_buf} = $rest;

    debug_packet(recv => $buf);

    $_[1] = $buf;
}

# Decode a packet
sub _decode_packet {
    my ($pkt) = @_;
    die 'Short packet received.' if length $pkt < 12;

    my ($size, $id, $type, $text) = unpack 'VV!Va*' => $pkt;
    die '[Mock] Received packet missing terminator' if $text !~ s/\0\0$//;

    ($size, $id, $type, $text);
}

# Debug display raw packet octets
sub debug_packet {
    return unless $TRACE;
    my ($how, $pkt) = @_;
    my ($size, $id, $type, $text) = unpack 'VV!Va*' => $pkt;
    my $raw = _printable $text;
    $how = $how eq 'send' ? ' -> send' : '<-  recv';

    my $term = $text =~ s/\0\0$// ? '' : '[NO TERM]';
    my $len = length $pkt;
    $id = sprintf "%02d", $id;
    diag "  $how\[sz:$size][id:$id][t:$type]<$text>$term";

}

# Warning helper. Matches *any* warning, even if multiple are present
sub warns_like(&$;$) {
    my ($code, $qr, $desc) = @_;
    my @warn = warnings { $code->() };
    if (any { /$qr/ } @warn) {
        ok 1, $desc;
    } else {
        fail $desc;
        diag "  |-> Warnings: @warn";
        diag "  `-> Expected warning to match $qr";
    }
}

1;
