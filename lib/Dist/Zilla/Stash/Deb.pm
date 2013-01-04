package Dist::Zilla::Stash::Deb;
use Moose;
with 'Dist::Zilla::Role::Stash';

# ABSTRACT: Stash for Dist::Zilla::Deb variables

has desc => (is => 'ro', isa => 'ArrayRef[Str]');
has architecture => (is => 'ro', isa => 'Str');
sub mvp_multivalue_args { return qw(desc) }

no Moose;
__PACKAGE__->meta->make_immutable;
