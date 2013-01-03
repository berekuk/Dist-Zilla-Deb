#!/usr/bin/perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More 0.88;

use Dist::Zilla::App::Tester;
use Path::Class;

# Workaround incompatibility between App::Cmd::Tester and CPAN.pm
require Debian::Control::FromCPAN;
# Workaround bug in Dist::Zilla::App::Tester
my $tmpdir = File::Temp::tempdir(CLEANUP => 1);$File::Temp::KEEP_ALL=1;

my $result = test_dzil('corpus/UseLess', [qw(debuild --us --uc --auto)],{tempdir => $tmpdir} );
note explain $result->log_events;

is($result->exit_code, 0, 'dzil debuild --auto ran successfully');
is($result->error, undef, '... and without throwing any error');

my $build_dir = $result->build_dir->absolute(dir($tmpdir, 'source')); # Hacky workaround for bug!

my $compat = $build_dir->file('debian', 'compat');
ok $compat->stat, 'debian/compat exists';
is $compat->slurp, "7\n", '... and has expected contents';

my $rules = $build_dir->file('debian', 'rules');
ok $rules->stat, 'debian/rules exists';
like $rules->slurp, qr/\t\bdh\b/, '... and contains a call to debhelper';

my $control = $build_dir->file('debian', 'control');
ok $control->stat, 'debian/control exists';

my @stanzas = split /\n\n/, $control->slurp;
is scalar @stanzas, 2, '... and has 2 sections';
my( $source, $package ) = @stanzas;

# Test source fields

like $source, qr/^Source: libuseless-perl\n/s, 'source package starts with Source: name';
like $source, qr/^Section: perl$/m, '... which has correct section';
like $source, qr/^Priority: optional$/m, '... and priority';
like $source, qr/^Build-Depends: debhelper .*, libmoose-perl,/m, '... and build-depends';
like $source, qr/^Build-Conflicts: libacme-bleach-perl \(>= 9999\)$/m, '... and build-conflicts';
TODO: {local $TODO = 'TODO'; like $source, qr/^Maintainer: M\. Aintainer <maintainer\@debian\.example\.org>$/m, '... and maintainer'; }
TODO: {local $TODO = 'TODO'; like $source, qr/^Uploaders: Foo Bar <foo\@example\.org>, Bar Foo <bar\@example\.org>$/m, '... and uploaders'; }
like $source, qr/^Standards-Version: [\d\.]+$/m, '... and there\'s a standard version';
like $source, qr|^Homepage: http://useless\.example\.org$|m, '... and correct homepage';

# Test fields in package

like $package, qr/^Package: libuseless-perl$/m, 'package section starts with Package: name';
like $package, qr/^Architecture: any$/m, '... and has correct architecture';
like $package, qr/^Depends: \$\{misc:Depends\}, \$\{perl:Depends\}, libmoose-perl/m, '... and depends';
like $package, qr/^Suggests: libacme-brainfck-perl$/m, '... and suggests';
like $package, qr/^Conflicts: libacme-bleach-perl \(>= 9999\)$/m, '... and conflicts';
like $package, qr/^Description: Test module for Dist-Zilla-Plugin-SimpleDebian\n Description line 1\n Description line 2\n \.\n And a final description line/m, '... and description';

done_testing;
