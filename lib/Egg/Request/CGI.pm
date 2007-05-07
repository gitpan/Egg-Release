package Egg::Request::CGI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: CGI.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Request::CGI - CGI.pm for Egg request.

=head1 DESCRIPTION

The request processing is done based on CGI.pm.

The following items of $e-E<gt>config-E<gt>{request} are evaluated.

=over 4

=item * POST_MAX

Maximum size of standard input when request method is POST.

=item * DISABLE_UPLOADS

Upload is not accepted when keeping effective.

=item * TEMP_DIR

Temporary preservation directory PATH of upload file.

=back

=cut
use strict;
use warnings;
use CGI;
use Carp 'croak';
use base qw/Egg::Request/;

our $VERSION= '2.00';

sub _setup_output {
	my($class, $e)= @_;
	my $conf= $e->config->{request} || {};
	if (my $max= $conf->{POST_MAX}) { $CGI::POST_MAX= $max }
	if (my $dup= $conf->{DISABLE_UPLOADS}) { $CGI::DISABLE_UPLOADS= $dup }
	if (my $tmp= $conf->{TEMP_DIR}) { $CGITempFile::TMPDIRECTORY= $tmp }
	$class->SUPER::_setup_output($e);
}

=head1 METHODS

=head2 new

CGI object is set in 'r' method.

=cut
sub new {
	my($class, $r, $e)= @_;
	my $req= $class->SUPER::new($r, $e);
	$req->r( Egg::Request::CGI::handler->new($r) );
	$req;
}
sub _prepare_params { $_[0]->r->Vars }

package Egg::Request::CGI::handler;
use strict;
use CGI qw/:cgi/;

our @ISA= 'CGI';

=head1 SEE ALSO

L<CGI>,
L<Egg::Request>,
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
