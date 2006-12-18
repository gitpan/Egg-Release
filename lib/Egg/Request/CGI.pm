package Egg::Request::CGI;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: CGI.pm 56 2006-12-18 12:25:28Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Request/;

our $VERSION= '0.03';

sub new {
	my $req = shift->SUPER::new(@_);
	my $conf= $req->e->config->{request} || {};
	$req->r( Egg::Request::CGI::base->new($req->r, $conf) );
	$req;
}
sub prepare_params {
	my($req, $icode)= @_;
	my $e= $req->e;
	my $params= $req->r->Vars;
	while (my($key, $value)= each %$params) {
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

package Egg::Request::CGI::base;
use strict;
use CGI qw/:cgi/;

our @ISA= 'CGI';

sub new {
	my($class, $r, $conf)= @_;

	$CGI::POST_MAX= $conf->{POST_MAX}
	  if $conf->{POST_MAX};

	$CGI::DISABLE_UPLOADS= $conf->{DISABLE_UPLOADS}
	  if $conf->{DISABLE_UPLOADS};

	$ENV{TMPDIR}= $conf->{TEMP_DIR}
	  if $conf->{TEMP_DIR};

	$Egg::CRLF= $CGI::CRLF;
	$class->SUPER::new($r);
}

1;

=head1 NAME

Egg::Request::CGI - CGI module is used and the request is processed.

=head1 SYNOPSIS

The setting that decides the behavior of CGI.pm can be written.

 request=> {
   POST_MAX       => 1024,
   DISABLE_UPLOADS=>    1,
   TEMP_DIR       => '/path/to/temp',
   },

When Egg::Plugin::Upload is used, this will become useful.

=head1 DESCRIPTION

Please use $e->request->r to call CGI object.

=head1 BUGS

All the outputs of the log of debug mode are treated as an error.

The cause seems the purpose is to send STDERR the message.
Place current improvement of this matter is not scheduled.
I am sorry.

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
