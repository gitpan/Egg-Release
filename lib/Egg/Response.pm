package Egg::Response;
#
# $Id: Response.pm 122 2007-05-10 18:21:18Z lushe $
#

=head1 NAME

Egg::Response - HTTP response processing for Egg.

=head1 SYNOPSIS

  # The response object is obtained.
  my $res= $e->response;
  
  # An original response header is set.
  $res->headers->header( 'X-ORIGN' => 'OK' );
  
  # Set Cookie is setup.
  $res->cookie( new_cookie => 'set_value' );
    or
  $res->cookies->{new_cookie}= 'set_value';
  
  # Refer to set Cookie.
  print $res->cookies->{new_cookie}->value;
  
  # The cash control is setup.
  $res->no_cache(1);
  
  # Redirect it.
  $res->redirect('/redirect_uri');
  
  # ...etc.

=head1 DESCRIPTION

This module offers processing and the function that relates to the HTTP 
response.

=head1 CONFIGURATION

=head2 cookie

The default of cookie can be setup.

  cookie => {
    domain  => 'mydomain',
    path    => '/',
    expires => '+3M',
    secure  => 0,
    },

=over 4

=item * domain

Domain that can be referred.

=item * path

PATH that can be referred.

=item * expires

Validity term.

=item * secure

Secure flag.

Warning: Cookie cannot be referred to from the connection of usual http.

=back

=cut
use strict;
use warnings;
use HTTP::Headers;
use CGI::Cookie;
use CGI::Util qw/expires/;
use base qw/Class::Accessor::Fast/;
use Carp qw/croak/;

__PACKAGE__->mk_accessors(qw/ e request nph status
  is_expires last_modified content_type content_language location /);

our $VERSION = '2.01';
our $CRLF    = "\015\012";
our $AUTOLOAD;

our %Status= (
  200 => 'OK',
  301 => 'Moved Permanently',
  302 => 'Moved Temporarily',
  303 => 'See Other',
  304 => 'Not Modified',
  307 => 'Temporarily Redirect',
  400 => 'Bad Request',
  401 => 'Unauthorized',
  403 => 'Forbidden',
  404 => 'Not Found',
  405 => 'Method Not Allowed',
  500 => 'Internal Server Error',
  );

sub _startup { @_ }

=head1 METHODS

=head2 new

Constructor. When the project is usually started, this is called.

* It is not necessary to call it specifying it.

=over 4

=item * BEGIN

=back

=cut
sub new {
	my($class, $e)= @_;
	bless {
	  e => $e,
	  body=> undef,
	  status=> 0,
	  location => "",
	  content_type => "",
	  content_language => "",
	  set_modified => ($e->config->{set_modified_constant} || 0),
	  }, $class;
}

=head2 request

Accessor to $e-E<gt>request.

=cut
sub request {
	$_[0]->{request} ||= $_[0]->e->request;
}

=head2 body ( [RESPONSE_CONTENT_BODY] )

The output contents are maintained by the SCALAR reference.

=cut
sub body {
	my $res= shift;
	return $res->{body} || 0 unless @_;
	$res->{body}= $_[0] ? (ref($_[0]) ? $_[0]: \$_[0]): return 0;
}

=head2 headers

L<HTTP::Headers> object is returned.

=cut
sub headers {
	$_[0]->{http_headers} ||= HTTP::Headers->new;
}

=head2 header ( [CONTENT_BODY] )

The HTTP response header is assembled and it returns it by the SCALAR reference.

When CONTENT_BODY is given, 'Content-Length' header is added.

=cut
sub header {
	my $res = shift;
#	return \$res->{header} if $res->{header};

	my($header, $body);
	my $leng_code= $res->request->is_head ? do {
		if ($body= shift) { $$body= "" }
		sub { };
	 }: ($body= shift and $$body) ? do {
		sub { $header.= "Content-Length: ".length($$body).$CRLF };
	 }: sub { };

	my $e= $res->e;
	my $headers= $res->{http_headers} || {};
	my($status, $content_type);
	if ($res->nph) {
		$header.= ($res->request->protocol || 'HTTP/1.0')
		       .  ($res->status || '200 OK'). $CRLF
		       .  'Server: '. $res->request->server_software
		       .  $CRLF;
	}
	if ($status= $res->status) {
		$header = 'Status: '
		       . $res->status. $res->status_string. $CRLF;
		$header.= 'Location: '
		       . $res->location. $CRLF if $status=~/^30[1237]/;
		if ($content_type= $res->content_type || "") {
			$header.= "Content-Type: $content_type$CRLF";
		}
	} else {
		$content_type= $res->content_type || $res->content_type(
		     $headers->{'content-type'}
		  || $e->config->{content_type}
		  || 'text/html'
		  );
		$header.= "Content-Type: $content_type$CRLF";
	}

	if ($content_type=~m{^text/.+}i) {
		if (my $language= $headers->{'content-language'}
		               || $res->content_language ) {
			$header.= "Content-Language: $language$CRLF";
		}
#		$leng_code->();
	} else {
		$leng_code->();
	}

	while (my($name, $value)= each %$headers) {
		next if $name=~/^Content\-(?:Type|Length|Language)$/i;
		$header.= ucfirst($name). "\: $_$CRLF"
		   for (ref($value) eq 'ARRAY' ? @$value: $value);
	}

	$header.= 'Date: '. expires(0,'http'). $CRLF
	    if ($res->{Cookies} or $res->is_expires or $res->nph);

	$header.= 'Expires: '. expires($res->is_expires). $CRLF
	    if $res->is_expires;

	$header.= 'Last-Modified: '. expires($res->last_modified). $CRLF
	    if $res->last_modified;

	if ($res->no_cache) {
		$header.= "Pragma: no-cache$CRLF"
		. "Cache-Control: no-cache, no-store, must-revalidate$CRLF";
	}
	if (my $cookies= $res->{Cookies}) {
		while (my($name, $hash)= each %$cookies) {
			my $value= CGI::Cookie->new(
			  -name   => $name,
			  -value  => $hash->{value},
			  -expires=> $hash->{expires},
			  -domain => $hash->{domain},
			  -path   => $hash->{path},
			  -secure => $hash->{secure},
			  ) || next;
			$header.= "Set-Cookie: $value$CRLF";
		}
	}
	$res->{header}= $header
	  . 'X-Egg-'. $e->namespace. ': '. $e->VERSION. $CRLF. $CRLF;
	\$res->{header};
}

=head2 cookie ( [KEY], [VALUE] )

Set Cookie is set.

If VALUE is a usual character string, it is considered the value value.
The following details can be set by giving the HASH reference.

  value   ... value of cookie.
  path    ... Reference PATH.  - Default is '/'.
  domain  ... Reference domain.
  expires ... Validity term.
  secure  ... Secure flag. - It starts making it to true at the SSL connection.

  $response->cookie( 'cookie_name' => {
    value   => 'cookie_value',
    path    => '/active',
    domain  => 'mydomain.name',
    expires => '+3H',
    secure  => 1,
    });

=cut
sub cookie {
	my $res= shift;
	return keys %{$res->cookies} if @_< 1;
	my $key= shift || return 0;
	@_ ? $res->cookies->{$key}= shift : $res->cookies->{$key};
}

=head2 cookies

The content of set Cookie is returned by the HASH reference.

=cut
sub cookies {
	my($res)= @_;
	$res->{Cookies} ||= do {
		$res->{cookies_ok}= 1;
		my %cookies;
		tie %cookies, 'Egg::Response::TieCookie', $res->e;
		\%cookies;
	  };
}

=head2 no_cache ( [BOOL], [EXPIRES], [LAST_MODIFIED] )

The cash control is set.

When EXPIRES is given, $response-E<gt>expires is set at the same time.
If $response-E<gt>expires is undefined, it defaults and '+1d' is set.

When LAST_MODIFIED is given, $response-E<gt>last_modified is set at the same time.
If $response-E<gt>expires is undefined, it defaults and '+1d' is set.

0 Becomes invalid if it gives it.
Moreover, please note that $response-E<gt>last_modified and $response-E<gt>is_expires
also set 0 at the same time.

  $response-E<gt>no_cache(1, '+3d', '+3d');

=cut
sub no_cache {
	my $res= shift;
	return $res->{no_cache} || 0 unless @_;
	if ($_[0]) {
		$_[1] ? $res->is_expires($_[1])
		      : ($res->is_expires || $res->is_expires('+1d'));
		$_[2] ? $res->last_modified($_[1])
		      : ($res->last_modified || $res->last_modified('+1d'));
		$res->{no_cache}= 1;
	} else {
		$res->is_expires(0);
		$res->last_modified(0);
		$res->{no_cache}= 0;
	}
}

=head2 attachment ( [FILE_NAME] )

The download file name is set.

As 'Content-disposition: attachment; filename=[FILE_NAME]' result, a is added
to the response header.

  $response-E<gt>attachment('download.file');

=cut
sub attachment {
	my $res= shift;
	$res->headers->{'Content-Disposition'}=
	           "attachment; filename=$_[0]" if $_[0];
}

=head2 window_target ( [TARGET_NAME] )

Window taget is specified.

=cut
sub window_target {
	my $res= shift;
	@_ ? $res->headers->{'Window-Target'}= shift
	   : ($res->headers->{'Window-Target'} || "");
}

=head2 content_encoding ( [ENCODING] )

content_encoding is specified.

=cut
sub content_encoding {
	my $res= shift;
	@_ ? $res->headers->{'Content-Encoding'}= shift
	   : ($res->headers->{'Content-Encoding'} || "");
}

=head2 status ( [STATUS_CODE] )

The status code is setup.

STATUS_CODE sets the figure of the treble that can surely be recognized with
the HTTP response header.

When STATUS_STRING is omitted, acquisition is tried from %Egg::Response::Status.

  $response-E<gt>status(400);

%Egg::Response::Status is as follows.

  200 ... OK
  301 ... Moved Permanently
  302 ... Moved Temporarily
  303 ... See Other
  304 ... Not Modified
  307 ... Temporarily Redirect
  400 ... Bad Request
  401 ... Unauthorized
  403 ... Forbidden
  404 ... Not Found
  405 ... Method Not Allowed
  500 ... Internal Server Error

The above-mentioned content is revokable from the controller etc.

  %Egg::Response::Status= (
    200 => 'OK',
    302 => 'Found',
    403 => 'Forbidden',
    404 => 'Not Found',
    500 => 'Internal Error',
    );

=head2 status_string

STATUS_STRING set with $response-E<gt>status is returned.

Half angle space is sure to be included in the head if it has defined it.

=cut
sub status_string {
	my $status= $_[0]->status    || return " $Status{200}";
	my $string= $Status{$status} || return "";
	" $string";
}

=head2 redirect ( [LOCATION_URI], [STATUS], [WINDOW_TARGET])

Redirecting is setup.

When STATUS is omitted, 302 is set.

When WINDOW_TARGET is specified, $response-E<gt>window_target is set at the
same time.

  $response-E<gt>redirect
     ( '/redirect', 307 => 'Temporarily Redirect', '_parent' );

=cut
sub redirect {
	my $res= shift;
	unless ($res->request->is_head) {
		my $location= shift || '/';
		my $status  = shift || 302;
		$res->window_target($_[0]) if $_[0];
		$res->location($location);
		$res->status($status);
	}
}

=head2 clear_body

The content of $response-E<gt>body is deleted.

=cut
sub clear_body {
	my($res)= @_;
	${$res->{body}}= undef if $res->{body};
}

=head2 clear_cookies

The content of $response-E<gt>cookies is initialized.

=cut
sub clear_cookies {
	tied(%{$_[0]->{Cookies}})->_clear if $_[0]->{Cookies};
}

=head2 clear

The main variable of the response object is initialized.

=cut
sub clear {
	my($res)= @_;
	$res->{content_type}= $res->{content_language}= "";
	$res->is_expires(0);
	$res->last_modified(0);
	$res->headers->clear if $res->{http_headers};
	$res->clear_cookies;
	undef($res->{header});
	1;
}

=head2 result

The result code corresponding to $response-E<gt>status is returned.

* Because this method is called from Egg by the automatic operation, it is
  not necessary to call it specifying it.

=cut
sub result  {
	my $code= $_[0]->status || return 0;
	$code== 200 ? 0: $code;
}

=head2 content_type ( [CONTENT_TYPE] )

The type of the output contents is setup.

As for default, 'content_type' of configuration or 'text/html' is used.

  $response-E<gt>content_type('image/png');

* The character set is not set by the automatic operation for the text system.
  Please include it in a set value.

  $response-E<gt>content_type('text/plain; charset=utf-8');

=head2 content_language ( [CONTENT_LANGUAGE] )

The language of contents is specified.

It defaults if 'content_language' of configuration is set and it is used.

  $response-E<gt>content_language('ja');

=head2 nph ( [BOOL] )

The flag to assemble the response header of NPH scripting is hoisted.

* As for this method, debugging is not completed.

=head2 is_expires ( [EXPIRES_VER] )

The Expires header is set.

  $response-E<gt>is_expires('+7d');

=head2 last_modified ( [LAST_MODIFIED_VAR] )

The last-Modified header is set.

  $response-E<gt>last_modified('+1H');

=cut

sub AUTOLOAD {
	my $res= shift;
	my($method)= $AUTOLOAD=~/([^\:]+)$/;
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{__PACKAGE__."::$method"}= sub { shift->headers->$method(@_) };
	$res->$method(@_);
}
sub DESTROY {
	my($res)= @_;
	untie %{$res->{Cookies}} if $res->{Cookies};
}

package Egg::Response::TieCookie;
use strict;
use Tie::Hash;

our @ISA = 'Tie::ExtraHash';

my $COOKIE  = 0;
my $SECURE  = 1;
my $DEFAULT = 2;

sub TIEHASH {
	my($class, $e)= @_;
	bless [{}, $e->request->secure,
	  ($e->config->{cookie_default} || {}) ], $class;
}
sub STORE {
	my $self= shift;
	my $key = shift || return 0;
	my $hash= $_[0] ? (ref($_[0]) eq 'HASH' ? $_[0]: { value=> $_[0] })
	                : { value => 0 };

	exists($hash->{value}) or die q{ I want cookie 'value'. };
	$hash->{name} ||= $key;

	$hash->{$_} ||= $self->[$DEFAULT]{$_} || undef
	  for qw/ domain expires path /;

	if (! defined($hash->{secure}) and $self->[$SECURE]) {
		$hash->{secure}= defined($self->[$DEFAULT]{secure})
		   ? $self->[$DEFAULT]{secure}: 1;
	}
	$self->[$COOKIE]{$key}= Egg::Response::FetchCookie->new($hash);
}
sub _clear { $_[0]->[$COOKIE]= {} }


package Egg::Response::FetchCookie;
use strict;
use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors(qw/name value path domain expires secure/);

sub new { bless $_[1], $_[0] }

=head1 SEE ALSO

L<HTTP::Headers>,
L<CGI::Cookie>,
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
