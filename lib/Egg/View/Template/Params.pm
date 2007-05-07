package Egg::View::Template::Params;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Params.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::View::Template::Params - Some parameters are set in Egg::View.

=head1 SYNOPSIS

  use Egg::View::Template::Params;
  
  # The call to E::V::Template::Params is added to '_prepare' call of Egg.
  sub _prepare {
    my($e)= @_;
    Egg::View::Template::Params->prepare($e);
    $e->next::method;
  }

=head1 DESCRIPTION

Some parameters are set to %PARAMS of Egg::View as a default value.

%PARAMS can be referred by the params method of received view and be set again.

=cut
use strict;
use warnings;
use Egg::View;

our $VERSION= '2.00';

=head1 METHODS

=head2 prepare ( [PROJECT_OBJ] )

Some parameters are set to %PARAMS of Egg::View.

When L<Egg::View::Template> is used, it is not necessary to set it separately
because this module is used by default.

Please it doesn't operate normally if you do not give PROJECT_OBJ.

When this method is called, the following parameters are set.

=over 4

=item * title

Title name of project on configuration

=item * page_title

Reference to $e-E<gt>page_title.

=item * script_name

Reference to $e-E<gt>request-E<gt>script_name.

=item * path

Reference to $e-E<gt>request-E<gt>path. 

=item * path_info

Reference to $e-E<gt>request-E<gt>path_info. 

=item * is_secure

Reference to $e-E<gt>request-E<gt>secure.

=item * remote_addr

Reference to $e-E<gt>request-E<gt>remote_addr.

=item * host_name

Reference to $e-E<gt>request-E<gt>host_name.

=item * server_port

Reference to $e-E<gt>request-E<gt>port.

=item * http_referer

Reference to $e-E<gt>request-E<gt>referer.

=item * http_agent

Reference to $e-E<gt>request-E<gt>agent.

=item * request_uri

Reference to $e-E<gt>request-E<gt>uri.

=item * copyright

'[PROJECT_NAME] Ver:[PROJECT_VERSION]'

=back

=cut
sub prepare {
	my($class, $e)= @_;
	my($conf, $req)= ($e->config, $e->request);

	my $params= {
	  title        => sub { $conf->{title} || '' },
	  page_title   => sub { $e->page_title },
	  script_name  => sub { $req->script_name },
	  path         => sub { $req->path },
	  path_info    => sub { $req->path_info },
	  is_secure    => sub { $req->secure },
	  remote_addr  => sub { $req->remote_addr },
	  host_name    => sub { $req->host_name },
	  server_port  => sub { $req->port },
	  http_referer => sub { $req->referer },
	  http_agent   => sub { $req->agent },
	  request_uri  => sub { $req->uri },
	  copyright    => sub { $e->namespace. " Ver:". $e->VERSION },
	  };

	%Egg::View::PARAMS= ( %$params, %Egg::View::PARAMS );
	@_;
}

=head1 SEE ALSO

L<Egg::View>,
L<Egg::View::Template>,
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
