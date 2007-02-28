package Egg::Response;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Response.pm 261 2007-02-28 19:32:16Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use HTTP::Headers;
use Egg::Response::TieCookie;
use CGI::Cookie;
use base qw/Egg::Component/;
no warnings 'redefine';

__PACKAGE__->mk_accessors
 ( qw/headers status content_type location no_cache ok_cache cookies_ok/ );

our $VERSION= '0.11';
our $AUTOLOAD;

*output   = \&body;
*set_cache= \&ok_cache;

sub new {
	my $res= shift->SUPER::new(@_);
	$res->{body}= $res->{status}= 0;
	$res->{headers}= HTTP::Headers->new;
	$res->content_type( $res->e->config->{content_type} || 'text/html' );
	$res;
}
sub body {
	my $res= shift;
	return $res->{body} if @_< 1;
	my($body)= @_;
	$res->{body}= ref($body) ? $body: \$body;
	${$res->{body}} ||= "";
	$res->{body};
}
sub create_header {
	my $res  = shift;
	my $body = ref($_[0]) ? $_[0]: \{};
	my($e, $headers, $CL)= ($res->e, $res->headers, $Egg::CRLF);

	my $header;
	my $ctype= $res->content_type || 'text/html';
	if ($ctype=~m{^text/}i && (my $lang=
	  $headers->{'content-language'} || $e->config->{content_language})) {
		$header.= "Content-Language: $lang$CL";
	}

	while (my($name, $value)= each %$headers) {
		next if $name=~/^Content\-(?:Type|Length|Language)$/i;
		$header.= "$name\: $_$CL" for (ref($value) eq 'ARRAY' ? @$value: $value);
	}

	if ($res->no_cache && HTTP::Date->require) {
		$header.= $res->create_no_cache($CL);
	} elsif ($res->set_cache && HTTP::Date->require) {
		$header.= $res->create_ok_cache($CL);
	}

	$header.= "Content-Length: ". length($$body). $CL if $res->status< 400;
	$header.= $res->create_cookies if $res->cookies_ok;
	$header.= "Content-Type: $ctype$CL";
	$header.= 'X-Egg-'. $e->namespace. ': '. $e->VERSION. "$CL$CL";
	\$header;
}
sub attachment {
	my $res= shift;
	$res->headers->header
	  ( 'content-disposition'=> "attachment; filename=$_[0]" ) if @_> 0;
	$res->headers->{'content-disposition'} || "";
}
sub create_no_cache {
	my($res, $CL)= @_;
	  "Expires: 0$CL"
	. "Pragma: no-cache$CL"
	. "Cache-Control: no-cache, no-store, must-revalidate$CL"
	. "Last-Modified: ". HTTP::Date::time2str(time). $CL;
}
sub create_ok_cache {
	my($res, $CL)= @_;
	 "Last-Modified: "
	. HTTP::Date::time2str(time+ $res->set_cache). $CL;
}
sub create_cookies {
	my($res)= @_;
	my $cookies;
	while (my($name, $hash)= each %{$res->cookies}) {
		my $value= CGI::Cookie->new(
		 -name   => $name,
		 -value  => $hash->{value},
		 -expires=> $hash->{expires},
		 -domain => $hash->{domain},
		 -path   => $hash->{path},
		 -secure => $hash->{secure},
		 ) || next;
		$cookies.= "Set-Cookie: $value$Egg::CRLF";
	}
	$cookies || "";
}
sub cookie {
	my $res= shift;
	return keys %{$res->cookies} if @_< 1;
	my $key= shift || return 0;
	$res->cookies->{$key}= shift if @_> 0;
	$res->cookies->{$key};
}
sub cookies {
	my($res)= @_;
	$res->{cookies} ||= do {
		$res->{cookies_ok}= 1;
		my %cookies;
		tie %cookies, 'Egg::Response::TieCookie', $res->e;
		\%cookies;
	  };
}
sub clear_cookies {
	my($res)= @_;
	%{$res->{cookies}}= ();
}
sub redirect {
	my $res     = shift;
	my $location= shift || '/';
	my $status  = shift || 302;
	$res->body(1);
	$res->{e}->template(0);
	$res->location($location);
	$res->status($status);
}
sub result {
	my($res)= @_;
	$res->{e}->request->result_status($res->status);
}
sub AUTOLOAD {
	my $res= shift;
	my($method)= $AUTOLOAD=~/([^\:]+)$/;
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{__PACKAGE__."::$method"}= sub { shift->{headers}->$method(@_) };
	$res->$method(@_);
}
sub DESTROY {
	my($res)= @_;
	untie %{$res->{cookies}} if $res->{cookies};
}

1;

__END__

=head1 NAME

Egg::Response - It processes it concerning the response of Egg.

=head1 SYNOPSIS

 # Access from Egg to this object.
 $e->response;  or $e->res;
 
 # Content-Type is set.
 $responce->content_type('image/png');
 
 # Contents are output.
 $responce->body('Hello, world!');
 
 # An original header is set.
 $responce->header( 'X-Orign' => 'foooo' );
   or
 $responce->push_header( 'X-Orign' => 'foooo' );
 
 # Redirect
 $response->redirect('http://domainname/', 307);
 
 etc..

=head1 DESCRIPTION

 It is a module that takes charge of the contents output of Egg. 

=head1 METHODS

=head2 $response->content_type([content type]);

output content type is set.

Please set $e->config->{content_type}. default is 'text/html'.

=head2 $response->no_cache([1 or 0]);

We will cast a spell so that a browser of the client should not cache it.

=head2 $response->set_cache([1 or 0]);

We will cast a spell so that a browser of the client may cache it.

=head2 $response->attachment([file_name]);

The 'Content-Disposition' header is set.

 content-disposition: attachment; filename=[file_name]

=head2 $response->body([content]);  or $response->output([content]);

It keeps it temporarily until contents are output.

It maintains it internally by the Scalar reference.

=head2 $response->create_header( $response->body );

Response header is assembled and it returns it.

=head2 $response->cookie([KEY NAME], [VALUE]);

Cookie is set with each key.

=head2 $response->cookies;

Set cookie is returned by HASH reference.

=head2 $response->clear_cookies;

All set cookie is canceled.

=head2 $response->create_cookies;

'Set-Cookie' header is assembled and it returns it.

=head2 $response->redirect([URL], [status code]);

Screen is forward to passed URL.

Status code can be set by the second argument. default is 302.

=head2 $response->status([status code]);

HTTP status code that wants to be returned at the end of processing is set.
(200, 404, 403, 500 etc..)

=head2 $response->headers;

Accessor to HTTP::Headers object.

=head1 SEE ALSO

L<HTTP::Headers>,
L<Egg::Request>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
