# About Minecraft::RCON

`Minecraft::RCON` is a Minecraft-specific implementation of the RCON
protocol, used to automate sending commands and receiving responses from a
Minecraft server.

With a properly configured server, you can use this module to automate many
tasks, and extend the functionality of your server without the need to mod
the server itself.

# Synopsis

```perl
    use Minecraft::RCON;

    my $rcon = Minecraft::RCON->new( { password => 'secret' } );

    eval { $rcon->connect };
    die "Connection failed: $@" if $@;

    my $response;
    eval { $response = $rcon->command('help') };
    say $@ ? "Error: $@" : "Response: $response";

    $rcon->disconnect;
```

# Documentation

Once this module is installed, full documentation is available via `perldoc
Minecraft::RCON` on your local system. Documentation for all releases is also
available on
[MetaCPAN](https://metacpan.org/pod/Minecraft::RCON)

# Installation

If you simply want the latest public release, install via CPAN.

If you need to build and install from this distribution directory itself,
run the following commands:

```sh
    perl Makefile.PL
    make
    make test
    make install
```

You may need to follow your system's usual build instructions if that doesn't
work. For example, Windows users will probably want to use `gmake` instead of
`make`. Otherwise, the instructions are the same.

# Support

 - [Issue Tracker](https://github.com/rjt-pl/Text-Trim/issues): Bug reports and feature requests
 - [GitHub Repository](https://github.com/rjt-pl/Minecraft-RCON)

# Authors

 - **Fredrik Vold** <<fredrik@webkonsept.com>> - Original (0.1.x) author.

 - **Ryan Thompson** <<rjt@cpan.org>> - 1.x+ maintainer. Fragmentation support, unit test suite, miscellaneous fixes and cleanup.

# License (Fredrik)

No copyright claimed, no rights reserved.

You are absolutely free to do as you wish with this code, but mentioning me in
your comments or whatever would be nice.

## Ryan Thompson's Modifications

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

[Artistic License](http://dev.perl.org/licenses/artistic.html)
