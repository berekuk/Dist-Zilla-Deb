package Dist::Zilla::App::Command::debrelease;

use strict;
use warnings;

# ABSTRACT: build and release debian package

=head1 DESCRIPTION

This command runs 'debrelease' command on sources built with 'dzil debuild'.

=cut

use Dist::Zilla::App -command;
require Dist::Zilla::App::Command::debuild;
use autodie qw(:all);

sub abstract { 'build and release debian package' }

sub opt_spec {}

sub execute {
    my ($self, $opt, $args) = @_;
    $self->app->execute_command($self->app->prepare_command('debuild'));
    system('cd debuild/source && debrelease');
}

1;
