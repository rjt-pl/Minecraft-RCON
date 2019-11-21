#!perl
use 5.008;
use strict;
use warnings FATAL => 'all';
use lib 't/lib';
use Test::Exception;
use Test::More;
use Local::Helpers;

use Minecraft::RCON;

my $rcon = Minecraft::RCON->new;

# color_mode
is  $rcon->color_mode, 'strip', 'Color mode strip by default';
throws_ok { $rcon->color_mode('') }       qr/Invalid color mode/;
throws_ok { $rcon->color_mode('strip ') } qr/Invalid color mode/;

is  $rcon->color_mode($_), $_, "`$_' is valid" for qw<strip convert ignore>;

is  $rcon->color_mode,'ignore',    'Color mode changed';

# Arrays to test strip, convert, and ignore color modes, respectively.
# Left side is input string, right is expected output.
# 3rd argument is an optional description. Otherwise, stripped 2nd is used.
my %modes = (
  strip => [
    ["Plain string"                 => 'Plain string'                       ],
    ["Color \x{00a7}4middle"        => 'Color middle'                       ],
    ["\x{00a7}3Color start"         => 'Color start'                        ],
    ["Color end\x{00a7}5"           => 'Color end'                          ],
    ["\x{00a7}3\x{00a7}4"           => '', 'Only colors'                    ],
    ["\x{00a7}3Two \x{00a7}4colors" => 'Two colors'                         ],
  ],
  convert => [
    ["Plain string"                 => "Plain string"                       ],
    ["Color \x{00a7}4middle"        => "Color \e[31mmiddle\e[0m"            ],
    ["\x{00a7}fColor start"         => "\e[97mColor start\e[0m"             ],
    ["Color end\x{00a7}5"           => "Color end\e[35m\e[0m"               ],
    ["\x{00a7}3\x{00a7}b"           => "\e[36m\e[96m\e[0m","Only colors"    ],
    ["\x{00a7}3Two \x{00a7}4colors" => "\e[36mTwo \e[31mcolors\e[0m"        ],
  ],
  ignore => [
    ["Plain string"                 => "Plain string"                       ],
    ["Color \x{00a7}4middle"        => "Color \x{00a7}4middle"              ], 
    ["\x{00a7}3Color start"         => "\x{00a7}3Color start"               ], 
    ["Color end\x{00a7}5"           => "Color end\x{00a7}5"                 ],
    ["\x{00a7}3\x{00a7}4"           => "\x{00a7}3\x{00a7}4","Only colors"   ],
    ["\x{00a7}3Two \x{00a7}4colors" => "\x{00a7}3Two \x{00a7}4colors"       ],
  ],
);

is $rcon->color_convert(''), '', 'Empty';

# Test color_mode() AND color_convert against %modes
my $was = $rcon->color_mode;
for my $mode (sort keys %modes) {
    $rcon->color_mode($mode);
    for (@{$modes{$mode}}) {
        my ($in, $out) = @$_;
        my $desc = "[$mode]  " . $rcon->color_convert($out, 'strip');

        is $rcon->color_convert($in, $mode), $out, $desc;

        $rcon->color_mode($mode);
        is $rcon->color_convert($in),        $out, $desc;
        $rcon->color_mode($was);
    }
}
$rcon->color_mode($was);

# Test $code variant of color_mode
$was = $rcon->color_mode('strip');
$rcon->color_mode(convert => sub {
    is $rcon->color_mode, 'convert', 'Color mode correct inside $code sub';
});
is $rcon->color_mode, $was, 'Color mode reset after $code';

done_testing;
