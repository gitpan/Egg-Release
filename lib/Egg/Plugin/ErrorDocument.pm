package Egg::Plugin::ErrorDocument;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: ErrorDocument.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;

our $VERSION= '0.02';

sub setup {
	my($e)= @_;
	my $conf= $e->config->{plugin_error_document} ||= {};

	$conf->{view_name} ||= do {
		my $view= $e->config->{VIEW}
		  || Egg::Error->throw('Please set up View.');
		$view->[0][0];
	  };
	$conf->{template_name}
	  || Egg::Error->throw('I want template_name.');
	$conf->{default_status} ||= 404;  ## NOT_FOUND.

	my $ignore= $conf->{ignore_status} || 200; ## OK
	my $code= $conf->{ignore_status_code}= {};
	$code->{$_}= 1 for (ref($ignore) eq 'ARRAY' ? @$ignore: $ignore);

	my %status= (
	  401 => 'AUTH_REQUIRED',
	  403 => 'FORBIDDEN',
	  404 => 'NOT_FOUND',
	  500 => 'SERVER_ERROR',
	  );
	$conf->{status_codeset} ||= {};
	$conf->{status_codeset}{$_} ||= $status{$_} for keys %status;

	$e->next::method;
}
sub error_document {
	my $e= shift;
	return if ++$e->{__error_document}> 1;
	my $res = $e->response;
	my $conf= $e->config->{plugin_error_document};
	my $code= $e->stash->{response_code}=
	  $res->status( shift || $conf->{default_status} );
	return if $conf->{ignore_status_code}{$code};
	my $view= $e->view($conf->{view_name})
	  || Egg::Error->throw("I want you setup of View. ($conf->{view_name})");
	$res->no_cache($conf->{no_cache});
	$res->status(200);
	$res->content_type($e->config->{content_type} || 'text/html');
	$e->page_title("$code - ". $e->response_status($code));
	my $body= $view->output($e, $conf->{template_name});
	$e->request->output($res->create_header($body), $body);
	$e->finished(200) unless $e->finished;
	$e;
}
sub response_status {
	my $e= shift;
	my $code= shift || '500';
	$e->config->{plugin_error_document}
	  {status_codeset}{$code} || 'INTERNAL_ERROR';
}

1;

__END__

=head1 NAME

Egg::Plugin::ErrorDocument - Plugin to display original error screen for Egg.

=head1 SYNOPSIS

  package MYPROJECT;
  use strict;
  sue Egg qw{ ErrorDocument };

Configuration.

  plugin_error_document=> {
    view_name      => 'Mason',
    template_name  => '/error/document.tt',
    default_status => 404,
    ignore_status  => 200,
    no_cache       => 1,
    },

Template : /MYPROJECT_ROOT/comp/error/document.tt

  <%init>
  my $code= $e->stash->{response_code};
  </%init>
  %
  <html>
  <head>
  <title><% $e->page_title %></title>
  </head>
  <body>
  <h1><% $e->page_title %></h1>
  <hr>
  <p>
  % if ($code == 401) {
  
    Un authorized. ..... ... ..
  
  % } elsif ($code == 403) {
  
    Forbidden. ..... ... ..
  
  % } elsif ($code == 404) {
  
    Object Not Found.  ..... ... ..
  
  % } elsif ($code == 500) {
  
    Internal Server Error. ..... ... ..
  
  % } else {
  
    Internal Error.  ..... ... ..
  
  % }
  </p>
  </body>
  </html>

=head1 DESCRIPTION

This plugin displays the original error page.

It doesn't live well in usual CGI and FastCGI though it only has to leave
'mod_perl' to the server now if an appropriate result code is returned when
processing is ended.
Then, this plug-in helps to make and to output the error page matched to the
response code.

Because it relies on a prescribed template, the place of VIEW and the template
for the template will be set to the configuration in making the error page.

=head1 CONFIGURATION

=head2 view_name

The name of View to handle the template is set.

As for default, the one whose priority level is the highest in the setting of
VIEW is used.

=head2 template_name

The template to generate the error page is set.

It should be a form that can be treated with View specified with view_name
though is not to saying.

There is no default. It makes an error of the unspecification.

=head2 default_status

The code that wants to do to the default when it is called like the response
status undefinition is set.

 Default is '404'.

=head2 ignore_status

The response code in which nothing is done is specified.

 Default is '200'.

=head2 status_codeset

The data to obtain the character corresponding to the status code is set by
the HASH reference.

 Default is {
   401 => 'AUTH_REQUIRED',
   403 => 'FORBIDDEN',
   404 => 'NOT_FOUND',
   500 => 'SERVER_ERROR',
   }

=head2 no_cache

When the error page is output, the no_cache header is included.

* I think the no_cache header also for the thing erased by the proxy etc. to
  exist. When the following sources are included in the template, it is more
  certain.

  <meta http-equiv="Pragma" content="no-cache">
  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">
  <meta http-equiv="expires" content="0">

=head1 METHODS

=head2 error_document ([STATUS_CODE])

It is called at the end of processing if it is assumed $e->finished(404) usually.

The error page is output to the making client.

=head2 response_status ([STATUS_CODE])

The character corresponding to the status code is returned.

'INTERNAL_ERROR' returns when the corresponding one is not found.

The data set with status_codeset is used.

=head1 SEE ALSO

L<Egg::Engine>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
