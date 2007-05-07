package Egg::Plugin::YAML;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: YAML.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::YAML - Plugin that treats YAML.

=head1 SYNOPSIS

  use Egg qw/ YAML /;

  $e->yaml_load($yaml_text);

=head1 DESCRIPTION

It is a plug-in to treat data and the file of the YAML form.

=cut
use strict;
use warnings;
use YAML;

our $VERSION= '2.00';

=head1 METHODS

=head2 yaml_load ( [YAML_DATA] or [YAML_PATH] )

Data or the file of the YAML form is read, and the result of doing PATH
is returned.

  $e->yaml_load('/path/to/load_file.yaml');

=cut
sub yaml_load {
	my $e   = shift;
	my $yaml= shift || return 0;
	$yaml=~/[\r\n]/ ? YAML::Load($yaml): YAML::LoadFile($yaml);
}

=head1 SEE ALSO

L<Egg::YAML>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
