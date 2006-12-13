package Egg::View::Template::Params;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id$
#
use strict;

our $VERSION= '0.01';

sub in {
	my($class, $view, $e)= @_;
	my($req, $cf)= ($e->request, $e->config);
	$view->{params}= {
	 title          => sub { $cf->{title} || '' },
	 content_charset=> sub { $cf->{content_charset} || '' },
	 script_name    => sub { $req->script_name },
	 is_secure      => sub { $req->secure },
	 remote_addr    => sub { $req->remote_addr },
	 server_name    => sub { $req->server_name },
	 server_port    => sub { $req->port },
	 http_referer   => sub { $req->referer },
	 http_agent     => sub { $req->agent },
	 request_uri    => sub { $req->uri },
	 copy_label     => sub { $e->namespace. " Ver:". $e->VERSION },
	 };
}

1;

__END__


=head1 NAME

Egg::View::Template::Params - Default parameter set for template driver that evaluates param.

=head1 SYNOPSIS

 $e->view->params( Egg::View::Template::Params->setup_params );

=head1 PARAMETERS

=head2 title

It is a set value of $e->config->{title}.

=head2 content_charset

It is a set value of $cf->{content_charset}.

=head2 is_secure

$e->request->secure is returned.

=head2 script_name

$e->request->script_name is returned.

=head2 remote_addr

$e->request->remote_addr is returned.

=head2 server_name

$e->request->server_name is returned.

=head2 http_referer

$e->request->referer is returned.

=head2 http_agent

$e->request->agent is returned.

=head2 http_agent

$e->request->uri is returned.

=head2 http_agent

'[PROJECT_NAME] Ver $e->VERSION' is returned.

=head1 SEE ALSO

L<Egg::Response>,
L<Egg::Template>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
