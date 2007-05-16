package Egg::Plugin::Request::ServerPort;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Body.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::Request::ServerPort - Server port is compelled by a set value.

=head1 SYNOPSIS

  use Egg qw/ Request::ServerPort /;
  
  __PACKAGE__->egg_startup(
    .......
    ...
    plugin_server_port => {
      http  => 80,
      https => 443,
      },
    );

  # A present server port is acquired.
  my $now_port= $e->request->server_port;

=head1 DESCRIPTION

It is a plug-in for $e-E<gt>request-E<gt>server_port to return the value of
the setting to the compulsion commutation ticket.

For instance, when the proxy is set up in the front end, and Egg is operated
by the back end, $e-E<gt>request-E<gt>server_port returns the port number of
the back end.

Therefore, it becomes a problem with 'http://domain.name:[PORT]/'
 in $e-E<gt>request-E<gt>uri etc. because it is returned.

This plugin solves such a problem.

=head1 CONFIGURATION

The setting is 'plugin_server_port'.

=head2 http

Returned port number usually.

Default is '80'.

=head2 https

Port number returned when $e-E<gt>secure is true.

Default is '443'.

=cut
use strict;
use warnings;

our $VERSION = '2.00';

sub _setup {
	my($e)= @_;
	my $port= $e->config->{plugin_request_port} ||= {};
	   $port->{http}  ||= 80;
	   $port->{https} ||= 443;
	$e->next::method;
}
sub _prepare {
	my($e)= @_;
	$ENV{SERVER_PORT}= $e->request->secure
	  ? $e->config->{plugin_request_port}{https}
	  : $e->config->{plugin_request_port}{http};
	$e->next::method;
}

=head1 SEE ALSO

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
