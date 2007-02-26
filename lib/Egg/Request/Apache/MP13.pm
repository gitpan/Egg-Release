package Egg::Request::Apache::MP13;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: MP13.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;
use warnings;
use Apache          ();
use Apache::Request ();
use Apache::File    ();
use Apache::Constants qw/:common/;
use base qw/Egg::Request::Apache/;

our $VERSION= '0.02';

sub setup {
	my($class, $e)= @_;
	my $base= $e->namespace;
	no strict 'refs';  ## no critic
	*{"Egg::handler"}= sub ($$) { shift; $base->run(@_) };
}
sub new {
	my $req= shift->SUPER::new(@_);
	my $conf= $req->e->config->{request} ||= {};
	$req->r( Apache::Request->new($req->r, %$conf) );
	$req;
}
sub result_status {
	my $req   = shift;
	my $status= shift || return &Apache::Constants::SERVER_ERROR;
	eval { $req->r->status($status) };
	return
	   $status== 200 ? &Apache::Constants::OK
	 : $status=~/30[1237]/ ? &Apache::Constants::REDIRECT
	 : $status== 401 ? &Apache::Constants::AUTH_REQUIRED
	 : $status== 403 ? &Apache::Constants::FORBIDDEN
	 : $status== 404 ? &Apache::Constants::NOT_FOUND
	 :                 &Apache::Constants::SERVER_ERROR;
}

1;

__END__

=head1 NAME

Egg::Request::Apache::MP13 - The request is processed by Apache::Request.

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

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
