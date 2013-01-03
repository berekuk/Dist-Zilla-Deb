use strict;
use warnings;
use Test::More 0.88;

use autodie;
use Dist::Zilla::Tester;
my $tzil = Dist::Zilla::Tester->from_config(
	{ dist_root => 'corpus/UseLess' },
);

$tzil->build;

my $control = $tzil->slurp_file('build/debian/control');

my @stanzas = split /\n\n/, $control;
is scalar @stanzas, 2, 'control has 2 sections';

my( $source, $package ) = @stanzas;

# Test source fields

like $source, qr/^Source: libuseless-perl\n/s, 'source package starts with Source: name';
like $source, qr/^Section: kernel$/m, '... which has correct section';
like $source, qr/^Priority: extra$/m, '... and priority';
like $source, qr/^Build-Depends: debhelper .*, libacme-bleach-perl$/m, '... and build-depends';
like $source, qr/^Build-Conflicts: libmoose-perl$/m, '... and build-conflicts';
like $source, qr/^Maintainer: M\. Aintainer <maintainer\@debian\.example\.org>$/m, '... and maintainer';
like $source, qr/^Uploaders: Foo Bar <foo\@example\.org>, Bar Foo <bar\@example\.org>$/m, '... and uploaders';
like $source, qr/^Standards-Version: [\d\.]+$/m, '... and there\'s a standard version';
like $source, qr|^Homepage: http://useless\.example\.org$|m, '... and correct homepage';

# Test fields in package

like $package, qr/^Package: libuseless-perl$/m, 'package section starts with Package: name';
like $package, qr/^Architecture: s390$/m, '... and has correct architecture';
like $package, qr/^Depends: \$\{misc:Depends\}, \$\{perl:Depends\}, libacme-bleach-perl/m, '... and depends';
like $package, qr/^Suggests: libacme-brainfck-perl$/m, '... and suggests';
like $package, qr/^Conflicts: libmoose-perl$/m, '... and conflicts';
like $package, qr/^Description: Test module for Dist-Zilla-Plugin-SimpleDebian\n Description line 1\n Description line 2\n \.\n And a final description line/m, '... and description';

done_testing;
