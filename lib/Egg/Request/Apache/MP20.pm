package Egg::Request::Apache::MP20;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: MP20.pm 55 2006-12-18 12:06:38Z lushe $
#
use strict;
use warnings;
use Apache2::Request     ();
use Apache2::RequestIO   ();
use Apache2::RequestRec  ();
use Apache2::RequestUtil ();
use Apache2::Response    ();
use Apache2::Connection  ();
use Apache2::Const -compile => qw/:common/;
use APR::Table ();
use base qw/Egg::Request::Apache/;

our $VERSION= '0.01';

sub new {
	my $req = shift->SUPER::new(@_);
	my $conf= $req->e->config->{request} || {};
	$req->r( Apache2::Request->new($req->r, %$conf) );
	$req;
}
sub result_status {
	my $req   = shift;
	my $status= shift || return &Apache2::Const::SERVER_ERROR;
	eval { $req->r->status($status) };
	return
	   $status== 200 ? &Apache2::Const::OK
	 : $status=~/30[1237]/ ? &Apache2::Const::REDIRECT
	 : $status== 401 ? &Apache2::Const::AUTH_REQUIRED
	 : $status== 403 ? &Apache2::Const::FORBIDDEN
	 : $status== 404 ? &Apache2::Const::NOT_FOUND
	 :                 &Apache2::Const::SERVER_ERROR;
}

1;

__END__


=head1 NAME

Egg::Request::Apache::MP20 - The request is processed by Apache2::Request.

=head1 DESCRIPTION

Apache2::Request seems not to be included in the mod_perl package of Fedora Core4.
It was possible to solve it in that case as follows.

 perl -MCPAN -e 'install Apache2::Request'

However, there might be a more straight method. I'm sorry.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<Egg::Request::Apache>,
L<Apache2::Request>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
