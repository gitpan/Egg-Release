package Egg::Plugin::rc;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: rc.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::rc - Loading the resource code file for Egg is supported.

=head1 SYNOPSIS

  use Egg qw/ rc /;

  my $rc= $e->load_rc;

=head1 DESCRIPTION

This plugin supports loading the resource code file for Egg.

Please prepare the resource code file in the following places.

  ./.egg_releaserc
  /project_root/.egg_releaserc
  ~/.egg_releaserc
  /etc/egg_releaserc

Moreover, please make the content YAML form.

* The part of egg_releaserc can be replaced by the value of $ENV{EGG_RC_NAME}.

=cut
use strict;
use warnings;
use YAML;

our $VERSION = '2.00';

=head1 METHODS

=head2 load_rc ( [ATTR_HASH] )

YAML::LoadFile is done if the rc file is found and the result is returned.

PATH can be set in current_dir and the rc file of an arbitrary place be read
to ATTR_HASH.

=cut
sub load_rc {
	my $e   = shift;
	my $attr= ref($_[0]) eq 'HASH' ? $_[0]: {@_};
	my $rc_name= $ENV{EGG_RC_NAME} || 'egg_releaserc';

	my($rc_file, $conf);
	if ($rc_file= $attr->{current_dir} and -e "$rc_file/.$rc_name") {
		$rc_file.= "/.$rc_name";
	} elsif ($conf= $e->config
	       and $rc_file= $conf->{root} and -e "$rc_file/.$rc_name") {
		$rc_file.= "/.$rc_name";
	} elsif (-e "~/.$rc_name")   { $rc_file = "~/.$rc_name";
	} elsif (-e "/etc/$rc_name") { $rc_file = "/etc/$rc_name";
	} else { return 0 }

	YAML::LoadFile($rc_file) || 0;
}

=head1 SEE ALSO

L<YAML>
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
