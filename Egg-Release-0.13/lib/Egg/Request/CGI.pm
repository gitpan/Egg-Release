package Egg::Request::CGI;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: CGI.pm 34 2006-12-14 08:17:52Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Request/;
use CGI qw/:cgi/;

our $VERSION= '0.01';

{
	no warnings 'redefine';
	sub param  { shift->SUPER::param(@_)  }
	sub cookie { shift->SUPER::cookie(@_) }
  };

sub new {
	my $req= shift->SUPER::new(@_);
	$req->r( CGI->new($req->r) );
	$req;
}
sub prepare_params {
	my($req, $icode)= @_;
	my $e= $req->e;
	while (my($key, $value)= each %{$req->r->Vars}) {
		next unless $value;
		$req->{parameters}{$key}= ref($value) eq 'ARRAY'
		 ? [map{$e->$icode(\$_)}@$value]: $e->$icode(\$value);
	}
}
sub output {
	my $req   = shift;
	my $header= shift || return 0;
	my $body  = ref($_[0]) ? $_[0]: \"";
	CORE::print STDOUT $$header. $$body;
	$req->{e}->debug_out($$header);
}

1;

=head1 NAME

Egg::Request::CGI - CGI module is used and the request is processed.

=head1 DESCRIPTION

Please use $e->request->r to call CGI object.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Request>,
CGI,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
