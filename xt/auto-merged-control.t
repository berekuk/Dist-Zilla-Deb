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
my $tmpdir = File::Temp::tempdir(CLEANUP => 1);

my $result = test_dzil("$FindBin::Bin/packages/auto-merged-control", [qw(debuild --us --uc --auto)],{tempdir => $tmpdir} );

is($result->exit_code, 0, 'dzil debuild --auto ran successfully');
is($result->error, undef, '... and without throwing any error');

ok( (grep { $_->{message} =~ m|writing\b.*\bdebian/control\b.*\bdebian/control\.in|i } @{$result->log_events}), '... and logged that it created control from template' );

my $build_dir = $result->build_dir->absolute(dir($tmpdir, 'source')); # Hacky workaround for bug!

my $control = $build_dir->file('debian', 'control');
ok $control->stat, 'debian/control exists';

my @stanzas = split /\n\n/, $control->slurp;
is scalar @stanzas, 3, '... and has 3 sections';
my( $source, $foo_package, $bar_package ) = @stanzas;

# Test source fields

like $source, qr/^Source: libauto-merged-control-perl\n/s, 'source package starts with Source: name';
like $source, qr/^Section: perl$/m, '... which has correct section';
like $source, qr/^Priority: optional$/m, '... and priority';
like $source, qr/^Build-Depends: debhelper .*, libmoose-perl,/m, '... and build-depends';
like $source, qr/^Maintainer: M\. Aintainer <maintainer\@debian\.example\.org>$/m, '... and maintainer';
like $source, qr/^Uploaders: Foo Bar <foo\@example\.org>, Bar Foo <bar\@example\.org>$/m, '... and uploaders';
like $source, qr/^Standards-Version: [\d\.]+$/m, '... and there\'s a standard version';

# Test fields in package

like $foo_package, qr/^Package: libauto-merged-control-perl-foo$/m, 'package section starts with Package: name';
like $foo_package, qr/^Architecture: any$/m, '... and has correct architecture';
like $foo_package, qr/^Depends: \$\{misc:Depends\}, \$\{perl:Depends\}, libmoose-perl/m, '... and depends';
like $foo_package, qr/^Description: test for auto merged control\n not a very long description$/m, '... and description';

done_testing;
