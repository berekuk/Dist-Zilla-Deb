package Dist::Zilla::App::Command::debi;

use strict;
use warnings;

# ABSTRACT: install generated debian package

=head1 DESCRIPTION

This command runs 'sudo debi' command on sources built with 'dzil debuild'.

=cut

use Dist::Zilla::App -command;
use autodie qw(:all);

sub abstract { 'install generated debian package' }

sub opt_spec {}

sub execute {
    my ($self, $opt, $args) = @_;
    system('cd debuild/source && sudo debi');
}

1;
