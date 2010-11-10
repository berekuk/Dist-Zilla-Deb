package Dist::Zilla::App::Command::debuild;

use strict;
use warnings;

use Dist::Zilla::App -command;
use Yandex::X;

sub abstract { 'build debian package' }

sub opt_spec {}

sub execute {
    my ($self, $opt, $args) = @_;

    xsystem('rm -rf .debuild');
    xmkdir('.debuild');
    $self->zilla->build_in('.debuild/source');
    xsystem('cd .debuild/source && debuild');
}

1;
