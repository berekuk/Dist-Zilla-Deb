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

sub opt_spec {
    # these options are propagated to debuild mostly for the tests
    # note than they should be specified as --us and will be transformed to -us because of getopt parsing differences
    ['us'   => "do not sign the source package"],
    ['uc'   => "do not sign the .changes file"],
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    die 'no args expected' if @$args;
}

sub execute {
    my ($self, $opt, $args) = @_;

    system('rm -rf debuild');
    mkdir('debuild');
    $self->zilla->build_in('debuild/source');
    my @debuild_args;
    push @debuild_args, '-us' if $opt->{us};
    push @debuild_args, '-uc' if $opt->{uc};
    system("cd debuild/source && debuild @debuild_args");
}

1;
