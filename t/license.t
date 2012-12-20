use strict;
use warnings;
use Test::More 0.88;
use autodie;
use Dist::Zilla::Tester;
my $tzil = Dist::Zilla::Tester->from_config(
	{ dist_root => 'corpus/UseLess' },
);

$tzil->build;

my $license = $tzil->slurp_file('build/debian/copyright');

like $license, qr/Copyright 1984 S\. Vindel & B\. Drag AS/, "Have copyright statement";
like $license, qr/^Upstream-Name: UseLess$/m, "Have upstream name";
like $license, qr/\n\nFiles: \*\n/, "Have Files: * paragraph";
like $license, qr/All rights reserved/, "Have all rights reserved";
like $license, qr|^Format: http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/$|m, "Have format url";

done_testing;
