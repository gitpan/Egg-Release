package Egg::Plugin::Charset;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Charset.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Charset - Base class for Charset plugin.

=head1 DESCRIPTION

It is a base class for the Charset plugin.

When '_convert_body' method is not prepared in the Charset plugin, the exception
is generated.

=cut
use strict;
use warnings;

our $VERSION = '2.00';

sub _finalize_output {
	my($e)= @_;
	$e->_convert_body( $e->response->body );
	$e->next::method;
}
sub _convert_body { die q{ Absolute method is not found. } }

=head1 SEE ALSO

L<Egg::Plugin::Charset::UTF8>,
L<Egg::Plugin::Charset::EUC_JP>,
L<Egg::Plugin::Charset::Shift_JIS>,
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
