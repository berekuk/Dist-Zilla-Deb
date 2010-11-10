package Dist::Zilla::App::Command::debc;

use strict;
use warnings;

# ABSTRACT: run debc on generated debian package

=head1 DESCRIPTION

This command runs 'debc' command on sources built with 'dzil debuild'.

=cut

use Dist::Zilla::App -command;
use Yandex::X;

sub abstract { 'run debc on generated debian package' }

sub opt_spec {}

sub execute {
    my ($self, $opt, $args) = @_;
    xsystem('cd debuild/source && debc');
}

1;
