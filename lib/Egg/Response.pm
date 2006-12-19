package Egg::Response;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@bomcity.com>
#
# $Id: Response.pm 57 2006-12-18 15:59:09Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use HTTP::Headers;
use Egg::Response::TieCookie;
use CGI::Cookie;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors
 ( qw/headers status location content_type no_cache ok_cache cookies_ok/ );

our $VERSION= '0.02';
our $AUTOLOAD;

*output   = \&body;
*set_cache= \&ok_cache;

sub setup {
	my($class, $e)= @_;
	my $red= $e->config->{redirect_page} ||= {};
	$red->{body_style}   ||= q/background:#FFEDBB; text-align:center;/;
	$red->{div_style}    ||= q/background:#FFF7ED; padding:10px; margin:50px; font:normal 12px sans-serif; border:#D15C24 solid 3px; text-align:left;/;
	$red->{h1_style}     ||= q/font:bold 20px sans-serif; margin:0px; margin-left:0px;/;
	$red->{default_url}  ||= '/';
	$red->{default_wait} ||= 0;
	$red->{top_location} ||= 0;
	$red->{default_msg}  ||= 'Processing was completed.';
}
sub new {
	my($class, $e)= @_;
	my $headers= HTTP::Headers->new;
	$e->config->{content_language}
	  and $headers->content_language($e->config->{content_language});
	bless {
	  e => $e,
	  body=> "",
 	  status=> 200,
	  headers => $headers,
	  content_type=> ($e->config->{content_type} || 'text/html'),
	  }, $class;
}
sub body {
	my $res= shift;
	return $res->{body} if @_< 1;
	my($body)= @_;
	$res->{body}= ref($body) ? $body: \$body;
	1;
}
sub attachment {
	my $res= shift;
	$res->headers->header
	  ( 'content-disposition'=> "attachment; filename=$_[0]" ) if @_> 0;
	$res->headers->{'content-disposition'} || "";
}
sub create_header {
	my $res = shift; my $e= $res->{e};
	my $body= ref($_[0]) ? $_[0]: \{};
	my($req, $headers, $CL)= ($e->request, $res->headers, $Egg::CRLF);
	my $header;
	my $ctype= $res->content_type || $header->content_type || "";
	if ($ctype=~m{^text/}i) {
		$header.= "Content-Language: $headers->{'content-language'}$CL"
		  if $headers->{'content-language'};
	}
	while (my($name, $value)= each %$headers) {
		next if $name=~/^Content\-(?:Type|Length|Language)$/i;
		$header.= "$name\: $_$CL" for (ref($value) eq 'ARRAY' ? @$value: $value);
	}
	if ($res->status< 400) {
		if ($res->no_cache && HTTP::Date->require) {
			$header.= $res->create_no_cache($CL);
		} elsif ($res->set_cache && HTTP::Date->require) {
			$header.= $res->create_ok_cache($CL);
		}
		$header.= "Conetnt-Length: ". length($$body). $CL;
	}
	$header.= $res->create_cookies if $res->cookies_ok;
	$header.= "Content-Type: $ctype$CL";
	$header.= 'X-Egg-'. $e->namespace. ': '. $e->VERSION
	       .  "$CL$CL";
	\$header;
}
sub create_no_cache {
	my($res, $CL)= @_;
	  "Expires: 0$CL"
	. "Pragma: no-cache$CL"
	. "Cache-Control: no-cache$CL"
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
		 -secure => ($hash->{secure} || 0),
		 ) || next;
		$cookies.= "Set-Cookie: $value$Egg::CRLF";
	}
	$cookies || "";
}
sub cookie {
	my $res= shift;
	return keys %{$res->cookies} if @_< 1;
	my $key= shift;
	$res->cookies->{$key}= shift if @_> 0;
	$res->cookies->{$key};
}
sub cookies {
	my($res)= @_;
	$res->{cookies} || do {
		my %cookies;
		my $conv= $res->{e}->config->{character_in}. '_conv';
		tie %cookies, 'Egg::Response::TieCookie', sub { $res->{e}->$conv(@_) };
		$res->{cookies}= \%cookies;
		$res->{cookies_ok}= 1;
		$res->{cookies};
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
sub redirect_page {
	my $res  = shift;
	my $conf = $res->{e}->config;
	my $rcf  = $conf->{redirect_page};
	my $url  = shift || $rcf->{default_url};
	my $msg  = shift || $rcf->{default_msg};
	my $attr = shift || {};
	my $wait = defined($attr->{wait}) ? $attr->{wait}: $rcf->{default_wait};
	my $popup= $attr->{alert} ? qq/ window.onload= alert('$msg'); /: "";
	my $body_style= $attr->{body_style} || $rcf->{body_style};
	my $div_style = $attr->{div_style}  || $rcf->{div_style};
	my $h1_style  = $attr->{h1_style}   || $rcf->{h1_style};
	my $clang= $res->headers->{'content-language'} || 'en';
	my $ctype= $res->content_type($conf->{content_type} || 'text/html');
	$res->status(200);
	<<END_OF_HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="$clang">
<head>
<meta http-equiv="content-language" content="$clang" />
<meta http-equiv="Content-Type" content="$ctype" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta http-equiv="refresh" content="$wait;url=$url" />
<script type="text/javascript"><!-- //
$popup
// --></script>
<style type="text/css">
body { $body_style }
div  { $div_style }
h1   { $h1_style }
</style>
</head>
<body>
<div>
<h1>$msg</h1>
<a href="$url">- Please click here when forwarding fails...</a>
</div>
</body>
</html>
END_OF_HTML
}
sub result {
	my($res)= @_;
	$res->{e}->request->result_status($res->status);
}
sub AUTOLOAD {
	my $res= shift;
	my($method)= $AUTOLOAD=~/([^\:]+)$/;
	no strict 'refs';
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

=head2 $response->redirect_page([URL], [MESSAGE], [OPTION]);

Screen is output and when changing, the fixed form contents are output once.

URL and message and option in argument.
Please pass the option by HASH reference.
Following values can be specified for option. 

 - wait      = Time until changing the screen every second. default is 0
 - alert     = Message is output with alert of JAVA script.
 - body_style= style of <body> is defined.
 - div_style = style of container is defined.
 - h1_style  = background of message and style of frame line are defined.

Configuration can do default.

 In the name of key, it is redirect_page and the content is HAHS reference.
 - default_url = Default when URL is not passed.
 - default_msg = Default when message is not passed.
 - default_wait= Time until changing the screen every second. default is 0
 - body_style, div_style, h1_style, etc.

Setting example.

 redirect_page=> {
   default_url => '/',
   default_msg => 'Please wait.',
   default_wait=> 1,
   body_style  => 'background:#FFEDBB; text-align:center;',
   div_style   => 'font-size:12px; border:#D15C24 solid 3px;',
   h1_style    => 'font:bold 20px sans-serif;',
   },

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

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
