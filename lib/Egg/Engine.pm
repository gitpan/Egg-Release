package Egg::Engine;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Engine.pm 203 2007-02-19 14:46:38Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use Egg::Exception;
use HTML::Entities;
use URI::Escape;

our $VERSION= '0.10';

*escape_html  = \&encode_entities;
*eHTML        = \&encode_entities;
*unescape_html= \&decode_entities;
*ueHTML       = \&decode_entities;
*escape_uri   = \&uri_escape;
*eURI         = \&uri_escape;
*unescape_uri = \&uri_unescape;
*ueURI        = \&uri_unescape;

{
	no warnings 'redefine';
	sub encode_entities {
		shift; my $args= $_[1] || q/\\\<>&\"\'/;
		&HTML::Entities::encode_entities($_[0], $args);
	}
	sub decode_entities
	  { shift; &HTML::Entities::decode_entities(@_) }
	sub encode_entities_numeric
	  { shift; &HTML::Entities::encode_entities_numeric(@_) }
	sub uri_escape
	  { shift; &URI::Escape::uri_escape(@_) }
	sub uri_escape_utf8
	  { shift; &URI::Escape::uri_escape_utf8(@_) }
	sub uri_unescape
	  { shift; &URI::Escape::uri_unescape(@_) }
  };

sub page_title {
	my($e)= @_;
	$e->dispatch->page_title || $e->config->{title} || "";
}
sub create_dispatch {
	my($e)= @_;
	my $dispatch= $e->dispatch_calss;
	$dispatch->_new($e);
}
sub prepare_component {
	my($e)= @_;
	$e->request->prepare || return $e->finished(403);  ## FORBIDDEN.
	$e->prepare_model;
	$e->prepare_view;
	$e->prepare;
	$e->dispatch( $e->create_dispatch );
}
sub prepare_model {
	my($e)= @_;
	for (@{$e->models}) {
		my $pkg= $e->model_class->{$_} || next;
		$e->{model}{$_}= $pkg->prepare($e) || next;
	}
}
sub prepare_view {
	my($e)= @_;
	for (@{$e->views}) {
		my $pkg= $e->view_class->{$_} || next;
		$e->{view}{$_}= $pkg->prepare($e) || next;
	}
}
sub run {
	local $SIG{__DIE__}= sub { Egg::Error->throw(@_) };
	my $class= shift;
	my $e= $class->new(@_);
	eval { $e->start_engine };
	if ($@) {
		my $error;
		if (my $class= ref($@)) {
			$error= $class eq 'Egg::Error' ? $@->stacktrace: $@;
		} else {
			$error= $@;
		}
		$e->finalize_error;
		my $comp= $e->template || '*';
		$e->log->notes("$comp: $error");
		$e->disp_error("$comp: $error");
	}
	$e->response->result;
}
sub startup   { @_ }
sub setup     { @_ }
sub prepare   { @_ }
sub execute   { @_ }
sub finalize  { @_ }
sub finalize_error { @_ }

sub view  { Egg::Error->throw('The method is not prepared.') }
sub model { Egg::Error->throw('The method is not prepared.') }
sub start_engine { Egg::Error->throw('The method is not prepared.') }

sub debug_report {
	my($e)= @_;
	my $Name= $e->namespace. '-'. $e->VERSION;
	my %list;
	for my $type (qw/model view/) {
		my $ucName= uc($type);
		$list{$type}= join ', ', map{
			my $pkg= $e->global->{"$ucName\_CLASS"}{$_};
			my $version= $pkg->VERSION || "";
			$_. ($version ? "-$version": "");
		  } @{$e->global->{"$ucName\_LIST"}};
	}
	my $report= 
	 "\n# << $Name start. --------------\n"
	 . "# + request-path : ". $e->request->path. "\n"
	 . "# + othre-class  : Req( " . $e->request_class . " ),"
	 .                   " Res( " . $e->response_class. " ),"
	 .                   " D( "   . $e->dispatch_calss. " )\n"
	 . "# + view-class   : $list{view}\n"
	 . "# + model-class  : $list{model}\n"
	 . "# + load-plugins : ". (join ', ', @{$e->plugins}). "\n";
	$e->request->param and do {
		my $params= $e->request->params;
		$report.= 
		   "# + in request querys:\n"
		 . (join "\n", map{"# +   - $_ = $params->{$_}"}keys %$params)
		 . "\n# + --------------------\n";
	  };
	$report;
}
sub debug_report_output {
	$_[0]->debug_out( $_[0]->debug_report );
}
sub output_content {
	my($e)= @_;
	return if $e->finished;
	my $res= $e->response;
	if (my($status)= $res->status=~/^(30[1237])/) {
		my $location= $res->location
		  || return $e->finished(500, q/Location is not specified./);
		my $header= $res->cookies_ok ? $res->create_cookies: "";
		$header.= "Status: $status Found$Egg::CRLF"
		       .  "Location: $location$Egg::CRLF$Egg::CRLF";
		$e->request->output(\$header);
	} else {
		my $body= $res->body;
		$e->request->output($res->create_header($body), $body);
	}
	$res->body(undef);
	return $e->finished(200) unless my $err= $@;
	return $e->finished(500, $err);
}
sub finished {
	my $e= shift;
	if (@_) {
		if (my $status= shift) {
			$status>= 500 and $e->log->notes(@_);
			$e->response->status($status);
			$e->{finished}= 1;
		} else {
			$e->response->status(0);
			$e->{finished}= 0;
		}
	}
	$e->{finished};
}
sub log {
	$_[0]->{__egg_log} ||= do {
		Egg::Debug::Log->require or Egg::Error->throw($@);
		Egg::Debug::Log->new($_[0]);
	 };
}
sub error {
	my $e= shift;
	if ($_[0]) {
		my $error= ref($_[0]) eq 'ARRAY' ? $_[0]: [$_[0]];
		Egg::Error->throw(@$error) unless ref($e);
		$e->{error} ? do { push @{$e->{error}}, $error }
		            : do { $e->{error}= $error };
	} elsif (defined($_[0])) {
		$e->{error}= undef;
	}
	$e->{error} || 0;
}
sub disp_error {
	Egg::Debug::Base->require or Egg::Error->throw($@);
	Egg::Debug::Base->disp_error(@_);
}
sub debug_out {
	Egg::Debug::Base->require or Egg::Error->throw($@);
	Egg::Debug::Base->debug_out(@_);
}

1;

__END__

=head1 NAME

Egg::Engine - Base class for Egg::Engin::*.

=head1 DESCRIPTION

This module is a base class for the engine.

Anything cannot be done in the unit.

=head1 METHODS

=head2 prepare_component

Prior of each component is prepared.

The following thing is concretely done.

  1 ... Call of $e->request->prepare
  2 ... prepare of effective each MODEL is called. 
  3 ... prepare of effective each VIEW is called. 
  4 ... prepare of each plugin is called.
  5 ... Generation of dispatch object.

This method will be called from Egg::Engine::*.

=head2 run

It processes it to the WEB request.

The following things are concretely done.

  1 ... The project object is generated. 
  2 ... start_engine of Egg::Engine::* is called.
  3 ... response->result is returned and processing is completed.

Processing moves as follows when the error occurs.

  1 ... Acquisition of error message
  2 ... finalize_error is called. 
  3 ... The log is output.
  4 ... Making of error screen.
  5 ... response->result is returned and processing is completed.

=head2 finished ([RESPONSE_CODE])

The end of processing is told.

As a result, some processing is canceled. 

Please give the argument the HTTP response code.

* The response code is set in response->status. 

* 0 Resets response->status when giving it.

  $e->finished(404);  ## NOT_FOUND

* It is good to use L<Egg::Const> if the response code is not understood easily.

  use Egg::Const;
  
  $e->finished( NOT_FOUND );

=head2 disp_error ([ERROR_MESSAGE])

The error screen is made. 

=head2 debug_out ([MESSAGE])

The message is output to STDERR. 

When debug mode is turning off, nothing is done.

=head2 output_content

response->The data output to body is output to the client.

* If finished is true, it has already canceled.

* If redirect is true, processing is divided.
  The content here might change in the future.
  However, I will have interchangeability.

=head2 log

The log object is returned.

=head2 error ([ERROR_MESSAGE])

The error message is accepted.

The error defined to omit messaging is returned by the ARRAY reference.

0 returns in case of undefined.

=head2 encode_entities ([HTML_TEXT], [ARGS])

It escapes in the HTML tag.

* L<HTML::Entities> is used.

Ailias is 'escape_html' and 'eHTML'.

=head2 decode_entities ([PLAIN_TEXT], [ARGS])

The HTML tag where it is escaped is restored.

* L<HTML::Entities> is used.

Ailias is 'unescape_html' and 'ueHTML'.

=head2 encode_entities_numeric ([HTML_TEXT])

The figure is made an escape object.

* L<HTML::Entities> is used.

=head2 uri_escape

URI is encoded.

Ailias is 'escape_uri' and 'eURI'.

* L<URI::Escape> is used.

=head2 uri_unescape

The URI decipherment is done.

Ailias is 'unescape_uri' and 'ueURI'.

* L<URI::Escape> is used.

=head2 uri_escape_utf8

Unicode also encodes URI to the object.

* L<URI::Escape> is used.

=head1 SEE ALSO

L<URI::Escape>,
L<HTML::Entities>,
L<Egg::Engine::V1>,
L<Egg::Exception>
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
