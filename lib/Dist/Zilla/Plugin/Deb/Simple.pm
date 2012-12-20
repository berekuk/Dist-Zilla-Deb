package Dist::Zilla::Plugin::Deb::Simple;
use Moose;
with 'Dist::Zilla::Role::InstallTool';
use 5.010;

use Carp;
use Debian::AptContents;
use Debian::Control::FromCPAN;
use Debian::Copyright 0.2;
use Dist::Zilla::File::InMemory;

# ABSTRACT: Create simple Debian package with Dist::Zilla

=encoding utf8

=head1 SYNOPSIS

Include in dist.ini:

 [Deb::Simple]
 desc = Package synopsis
 desc = Description of the package.
 desc = Might be more than on line.

=head1 DESCRIPTION

This L<Dist::Zilla> plugin writes most of the files necessary to
create a simple Debian package from the CPAN-style distribution that
you create with dzil.

Figuring out debian dependencies from the CPAN module dependencies in
dzil is done by the logic from L<DhMakePerl>.

You will need to maintain F<debian/changelog> manually.

When the distribution is created there will be the following files in
F<debian/>:

=over

=item F<control>

This file contains almost all the package metadata. Values are taken
from Dist::Zilla's core attributes when possible, others are set or
overridden by this plugins attributes.

=item F<copyright>

A very simple copyright file containing the full text of the
distribution's license, as produced by the fulltext method of the
dist's L<Software::License> object.

=item F<compat>

Contains our debhelper compatibility level.

=item F<rules>

A static file containing the default simple debhelper rules.

=back

=attr desc

Description. Should be given multiple times, the first one is the
single line synopsis, the rest are lines of the extended
description.

To get a paragraph break simply add an C<desc = > line without a
value.

This is the only mandatory argument.

=cut

has desc => (is => 'ro', isa => 'ArrayRef[Str]', required => 1);

=attr source_name

Name of source package. Defaults to C<lib$name-perl> with C<$name>
being the distribution name from dzil but lowercased and with ::
replaced by -.

=cut

has source_name => (is => 'ro', isa => 'Str');

=attr package_name

Name of binary package. Defaults to the same thing as C<source_name>

=cut

has package_name => (is => 'ro', isa => 'Str');

=attr maintainer

Package maintainer. Defaults to the first author.

=cut

has maintainer => (is => 'ro', isa => 'Str');

=attr uploader

Package co-maintainer. Optional, and can be given multiple times.

=cut

has uploader => (is => 'ro', isa => 'ArrayRef[Str]');

=attr section

Which section of the archive the package should be in. Defaults to
perl.

=cut

has section => (is => 'ro', isa => 'Str', default => 'perl');

=attr priority

Package priority. Defaults to optional.

=cut

has priority => (is => 'ro', isa => 'Str', default => 'optional');

=attr homepage

URL of the web site for the package. Optional, defaults to homepage
from the distribution meta data (can be set with
L<Dist::Zilla::Plugin::MetaResources>)

=cut

has homepage => (is => 'ro', isa => 'Maybe[Str]', lazy_build => 1);
sub _build_homepage { shift->zilla->distmeta->{resources}{homepage} }

=attr architecture

Architecture for the binary package. Defaults to all.

Set this to any if your distribution has XS or other compiled parts.

=cut

has architecture => (is => 'ro', isa => 'Str', default => 'all');

=attr compat

Debhelper compatibility level. Defaults to 7, which is probably what
you want it to be.

=cut

has compat => (is => 'ro', isa => 'Str', default => "7\n");
has _rules => (is => 'ro', isa => 'Str', default => <<'EOF');
#!/usr/bin/make -f

%:
	dh $@
EOF

has _apt_contents => (is => 'ro', isa => 'Debian::AptContents', lazy_build => 1);
sub _build__apt_contents { Debian::AptContents->new( { homedir => "$ENV{HOME}/.dh-make-perl" } ) }

sub mvp_multivalue_args { return qw(uploader desc) }

sub setup_installer {
	my( $self ) = @_;

	$self->add_file(
		Dist::Zilla::File::InMemory->new({
			name => 'debian/compat',
			content => $self->compat,
	}));

	$self->add_file(
		Dist::Zilla::File::InMemory->new({
			name => 'debian/rules',
			content => $self->_rules,
			mode => 0755,
	}));

	#
	# Create control file
	#
	my $control_str = $self->_generate_control();

	$self->add_file(
		Dist::Zilla::File::InMemory->new({
			name => 'debian/control',
			content => $control_str,
	}));

	#
	# Create copyright file
	#
	my $copyright_str = $self->_generate_copyright();

	$self->add_file(
		Dist::Zilla::File::InMemory->new({
			name => 'debian/copyright',
			content => $copyright_str,
	}));

	return
}

sub _generate_control {
	my ( $self ) = @_;

	my $control = Debian::Control::FromCPAN->new();

	# Source package
	$control->source->Source( $self->source_name // 'lib' . lc($self->zilla->name) . '-perl' );
	$control->source->Section( $self->section );
	$control->source->Priority( $self->priority );
	$control->source->Maintainer( $self->maintainer // $self->zilla->authors->[0] );
	$control->source->Uploaders->add( $_ ) for @{$self->uploader // []};
	$control->source->Standards_Version( '3.9.1' );
	$control->source->Homepage( $self->homepage ) if $self->homepage;
	$control->source->Build_Depends( 'debhelper (>= 7)' );

	# Binary package
	my $pkg_name = $self->package_name // 'lib' . lc($self->zilla->name) . '-perl';
	my $pkg = Debian::Control::Stanza::Binary->new( { Package => $pkg_name } );
	$control->binary->Push( $pkg_name => $pkg );

	$pkg->Architecture( $self->architecture );
	$pkg->Depends->add('${misc:Depends}', '${perl:Depends}');
	$pkg->Description( join( "\n ", map { $_ || '.' }
		$self->zilla->abstract,
		@{$self->desc},
	));

	$self->_add_prereqs($control, build => 'requires');
	$self->_add_prereqs($control, build => 'conflicts');

	$self->_add_prereqs($control, runtime => 'requires');
	$self->_add_prereqs($control, runtime => 'recommends');
	$self->_add_prereqs($control, runtime => 'suggests');
	$self->_add_prereqs($control, runtime => 'conflicts');

	# Write control file
	my $control_str;
	$control->write( \$control_str );

	return $control_str;
}

sub _add_prereqs {
	my( $self, $control, $phase, $relationship ) = @_;
	croak 'invalid phase' unless $phase eq 'build' or $phase eq 'runtime';

	# Find the field in debian/control where we want to put these
	# prereqs

	my $debian_relationship = ucfirst($relationship);
	$debian_relationship = 'Depends' if $debian_relationship eq 'Requires';

	my $control_field;
	if( $phase eq 'build' ){
		$control_field = 'Build_' . $debian_relationship;
		$control_field .= '_Indep' if not $control->is_arch_dep;
		$control_field = $control->source->$control_field;
	}
	else {
		$control_field = $control->binary->Values(0)->$debian_relationship;
	}

	# Get the list of required perl modules

	my $prereqs = $self->zilla->prereqs;

	my $requirements = $prereqs->requirements_for($phase, $relationship)->clone;
	if( $phase eq 'build' ){
		$requirements->add_requirements(
			$prereqs->requirements_for($_, $relationship)
		) for qw(configure runtime test);
	}
	$requirements = $requirements->as_string_hash;

	# Special case for the requirement on perl

	if( my $perl_requirement = delete $requirements->{perl} ){
		$perl_requirement = version->parse($perl_requirement)->normal;
		$perl_requirement =~ s/^v//;
		$control_field->add( Debian::Dependency->new(perl => $perl_requirement) );
	}

	# Map modules to debian packages

	my( $packages, $missing_packages ) = $control->find_debs_for_modules( $requirements, $self->_apt_contents );
	if( @$missing_packages ){
		die "Need the following for $phase/$relationship "
		. 'for which there are no debian packages available: '
		. join(', ', @$missing_packages);
	}

	$control_field->add($packages);

	return;
}

sub _generate_copyright {
	my( $self ) = @_;
	my $copyright = Debian::Copyright->new();
	$copyright->header( Debian::Copyright::Stanza::Header->new( {
		Upstream_Name => $self->zilla->name,
		Format => 'http://www.debian.org/doc/packaging-manuals/copyright-format/1.0/',
	}));

	my $license = $self->zilla->license->name . "\n" . $self->zilla->license->license;
	$license = join "\n ", map {$_ || '.'} split( /\n/, $license );
	$copyright->files->Push('*' => Debian::Copyright::Stanza::Files->new({
		Files => '*',
		Copyright => 'Copyright ' . $self->zilla->license->year . ' ' . $self->zilla->license->holder,
		License => $license,
	}));

	# Write control file
	my $string;
	$copyright->write( \$string );

	return $string;
}
no Moose;
__PACKAGE__->meta->make_immutable;
