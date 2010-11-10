package Dist::Zilla::App::Command::debrelease;

use strict;
use warnings;

use Dist::Zilla::App -command;
require Dist::Zilla::App::Command::debuild;
use Yandex::X;

sub abstract { 'build and release debian package' }

sub opt_spec {}

sub execute {
    my ($self, $opt, $args) = @_;
    $self->app->execute_command($self->app->prepare_command('debuild'));
    xsystem('cd .debuild/source && debrelease');
}

1;
