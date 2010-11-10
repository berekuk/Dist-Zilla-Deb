package Dist::Zilla::App::Command::debc;

use strict;
use warnings;

use Dist::Zilla::App -command;
use Yandex::X;

sub abstract { 'run debc on generated debian package' }

sub opt_spec {}

sub execute {
    my ($self, $opt, $args) = @_;
    xsystem('cd .debuild/source && debc');
}

1;
