package Egg::Request::CGI;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: CGI.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Request/;
no warnings 'redefine';

our $VERSION= '0.09';

sub setup {
	my($class, $e)= @_;
	$class->setup_config($e->config->{request});
	$class->SUPER::setup($e);
}
sub setup_config {
	my $class= shift;
	my $conf = shift || {};

	$CGI::POST_MAX= $conf->{POST_MAX}
	  if $conf->{POST_MAX};
	$CGI::DISABLE_UPLOADS= $conf->{DISABLE_UPLOADS}
	  if $conf->{DISABLE_UPLOADS};
	$CGITempFile::TMPDIRECTORY= $conf->{TEMP_DIR}
	  if $conf->{TEMP_DIR};
	$Egg::CRLF= $CGI::CRLF;

	@_;
}
sub new {
	my($class, $e, $r)= @_;
	my $req= $class->SUPER::new($e, $r);
	$req->r( Egg::Request::CGI::base->new($r) );
	$req;
}
sub prepare_params {
	my($req)= @_;
	$req->{parameters}= $req->r->Vars;
}
sub output {
	my $req   = shift;
	my $header= shift || return 0;
	my $body  = ref($_[0]) ? $_[0]: \"";
	CORE::print STDOUT $$header, $$body;
	$req->{e}->debug_out($$header);
}

package Egg::Request::CGI::base;
use strict;
use CGI qw/:cgi/;

our @ISA= 'CGI';

1;

__END__

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

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
