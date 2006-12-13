package Egg::Request::Apache::MP19;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id$
#
use strict;
use Apache2             ();
use Apache::Request     ();
use Apache::Response    ();
use Apache::RequestIO   ();
use Apache::RequestRec  ();
use Apache::RequestUtil ();
use Apache::Connection  ();
use Apache::Compat      ();
use Apache::Upload      ();
use Apache::Const -compile => qw/:common/;
use base qw/Egg::Request::Apache/;

our $VERSION= '0.01';

sub new {
	my $req= shift->SUPER::new(@_);
	$req->r( Apache::Request->new($req->r) );
	$req;
}
sub result_status {
	my $req   = shift;
	my $status= shift || return &Apache::Const::SERVER_ERROR;
	eval { $req->r->status($status) };
	return
	   $status== 200 ? &Apache::Const::OK
	 : $status=~/30[1237]/ ? &Apache::Const::REDIRECT
	 : $status== 401 ? &Apache::Const::AUTH_REQUIRED
	 : $status== 403 ? &Apache::Const::FORBIDDEN
	 : $status== 404 ? &Apache::Const::NOT_FOUND
	 :                 &Apache::Const::SERVER_ERROR;
}

1;

__END__


=head1 NAME

Egg::Request::Apache::MP19 - The request is processed by Apache::Request.

=head1 DESCRIPTION

B<Warning:>

This module doesn't complete debug because there is no environment 
that operates this module at all.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
L<Egg::Request::Apache>,
L<Apache::Request>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
