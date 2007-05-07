package Egg::Plugin::ErrorDocument;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: ErrorDocument.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Plugin::ErrorDocument - Plugin that generates error screen.

=head1 SYNOPSIS

  use Egg qw/ ErrorDocument /;
  
  __PACKAGE__->egg_startup(
    ...
    .....
  
    plugin_error_document => {
      view_name => 'Template',
      template  => 'error.tmpl',
      include_ignore_status => 403,
      },
  
  );

=head1 DESCRIPTION

It is a plugin to generate the error screens such as '404 Not Found' and
'500 Server Error'.

The WEB server doesn't generate the error screen only with the return of the
status code such as 404 when operating excluding the mod_perl environment.
This plugin supplements it.
Of course, it is possible to use it even in the mod_perl environment.

The error screen that this plugin intervenes is an error screen when processing
can be normally completed.
The error screen concerning the exception becomes the debugging screen of Egg.

The error screen is made by set arbitrary VIEW.

To acquire the status code easily on the VIEW side, following parameter is set.

  VIEW-E<gt>param('status'),
  VIEW-E<gt>param('status_[STATUS_CODE]'),

Especially, being able to do only the condition judgment by the presence of
the value in L<HTML::Template> can correspond by doing as follows.

  <TMPL_IF NAME="status_404">
    ... 404 Not Found.
  <TMPL_ELSE>
  <TMPL_IF NAME="status_403">
    ... 403 Forbidden.
  <TMPL_ELSE>
    ... 500 Internal Server Error.
  </TMPL_IF>
  </TMPL_IF>


=head1 CONFIGURATION

=head2 view_name => [VIEW_NAME]

VIEW to make the error screen is specified.

  view_name => 'Mason',

* There is no default. When it is unspecification, the exception is generated.

=head2 template => [TEMPLATE]

The template of the error screen is specified.

It is a template for VIEW specified by 'View_name' and it is necessary to exist.

  template => 'document/error.tt',

=head2 ignore_status => [STATUS_ARRAY],

The list of the status code of off the subject is specified.

Default is 200, 301, 302, 303, 304, 307,

  ignore_status => [qw/ 200 301 302 303 304 307 403 /],

=head2 include_ignore_status => [STATUS_ARRAY],

List of status code added to 'ignore_status'.

  include_ignore_status => 403,

=cut
use strict;
use warnings;
use Egg::Response;

our $VERSION= '2.00';

my $Status= \%Egg::Response::Status;

sub _setup {
	my($e)= @_;
	my $conf= $e->config->{plugin_error_document} ||= {};

	$conf->{view_name} ||= do {
		my $view= $e->config->{VIEW} || die q{ I want setup 'VIEW' };
		$view->[0][0];
	  };

	$conf->{template} || die q{ I want setup 'template'. };
	my $ignore= $conf->{ignore_status} || [qw/ 200 301 302 303 304 307 /];
	   $ignore= [$ignore] unless ref($ignore) eq 'ARRAY';
	if (my $in= $conf->{include_ignore_status}) {
		splice @$ignore, 0, 0, (ref($in) eq 'ARRAY' ? @$in: $in);
	}

	my $code= $e->global->{error_document_ignore_status}= {};
	$code->{$_}= 1 for @$ignore;

	$e->next::method;
}
sub _finalize_output {
	my($e)= @_;

	my $status= $e->response->status || return $e->next::method;
	return $e->next::method if $e->request->is_head;
	return $e->next::method
	    if $e->global->{error_document_ignore_status}{$status};

	my $conf= $e->config->{plugin_error_document};

	my $res= $e->response;
	$e->page_title( "$status -". $res->status_string );
	$res->no_cache(1)                    if defined($conf->{no_cache});
	$res->status($conf->{result_status}) if defined($conf->{result_status});
	$res->content_type( $conf->{content_type}
	                 || $e->config->{content_type}
	                 || 'text/html' );
	my $view= $e->view( $conf->{view_name} )
	       || die qq{ VIEW of '$conf->{view_name}' is not found. };
	$view->param ( status => $status );
	$view->param ( "status_$status" => 1 );
	$view->output( $conf->{template} );

	$e->next::method;
}

=head1 SEE ALSO

L<Egg::View>,
L<Egg::View::Mason>,
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
