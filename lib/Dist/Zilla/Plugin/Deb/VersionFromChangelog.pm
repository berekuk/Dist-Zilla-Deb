package Dist::Zilla::Plugin::Deb::VersionFromChangelog;

use Moose;
use autodie;
with 'Dist::Zilla::Role::BeforeBuild';

sub before_build {
    my ($self) = @_;
    my $zilla = $self->zilla;
    my $changelog_file = $zilla->root.'/debian/changelog';
    unless (-e $changelog_file) {
        confess("$changelog_file not found");
    }

    open(my $fh, '<', $changelog_file);
    my $first_line = <$fh>;
    chomp $first_line;
    my ($version) = $first_line =~ m{^\S+\s+\((\S+)\)} or die "Invalid first line '$first_line'";
    # TODO - remove trailing '-$build' from debian version?
    $zilla->version($version);
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

