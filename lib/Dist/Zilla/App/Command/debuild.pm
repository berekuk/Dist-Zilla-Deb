package Dist::Zilla::App::Command::debuild;

use strict;
use warnings;

# ABSTRACT: build debian package

=head1 DESCRIPTION

This command builds sources using dzil and runs debuild on them.

Sources are kept in 'debuild/source'.

=cut

use Dist::Zilla::App -command;
use autodie qw(:all);

sub abstract { 'build debian package' }

sub opt_spec {}

sub execute {
    my ($self, $opt, $args) = @_;

    system('rm -rf debuild');
    mkdir('debuild');
    $self->zilla->build_in('debuild/source');
    system('cd debuild/source && debuild');
}

1;
