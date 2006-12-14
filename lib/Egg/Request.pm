package Egg::Request;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno <mizuno@bomcity.com>
#
# $Id$
#
use strict;
use warnings;
use Error;
use base qw/Class::Accessor::Fast/;
use CGI::Cookie;

__PACKAGE__->mk_accessors
 ( qw/e r debug parameters uploads secure scheme path/ );

our $VERSION= '0.02';

*address= \&remote_addr;
*port   = \&server_port;
*agent  = \&user_agent;
*params = \&parameters;

sub setup { }

sub new {
	my $class= shift;
	my $e= shift || throw Error::Simple q/I want Egg object./;
	my $r= shift || undef;
	bless {
	 e=> $e, r=> $r, debug=> $e->debug,
	 parameters=> {}, args=> {}, uploads=> {},
	 }, $class;
}
sub param {
	my $req= shift;
	return keys %{$req->{parameters}} if @_< 1;
	my $key= shift;
	$req->{parameters}{$key}= shift if @_> 0;
	$req->{parameters}{$key};
}
sub cookie {
	my $req= shift;
	my $cookie= $req->cookies;
	return keys %$cookie if @_== 0;
	exists($cookie->{$_[0]}) ? $cookie->{$_[0]}: undef;
}
sub cookies {
	my($req)= @_;
	$req->{cookies} || do {
		$req->{cookies}= fetch CGI::Cookie || {};
		$req->{cookies};
	  };
}
sub prepare {
	my($req)= @_;
	my $config= $req->e->config;

	my $secure= (($ENV{HTTPS} && lc($ENV{HTTPS}) eq 'on')
	 || ($ENV{SERVER_PORT} && $ENV{SERVER_PORT}== 443)) ? 1: 0;
	$req->secure($secure);
	$req->scheme($secure ? 'https': 'http');

	my $path;
	if ($ENV{REDIRECT_URL}) {
		$path= $ENV{REDIRECT_URL};
		$path=~s{$ENV{PATH_INFO}$} [];
	} else {
		$path= $ENV{SCRIPT_NAME} || '/';
	}
	$ENV{PATH_INFO} and $path.= $ENV{PATH_INFO};

	$path=~m{^/} ? do { $req->path($path); $path=~s{^/} [] }
	             : do { $req->path("/$path") };

	$req->e->snip([(split /\//, $path)]);

	$req->prepare_params("$config->{character_in}_conv");
	1;
}
sub prepare_params {
	my($req)= @_;
	my $r= $req->r;
	$req->{params}{$_}= $r->param($_) for $r->param;
}
sub header {
	my $req = shift;
	my $name= lc(shift) || return "";
	$name=~s/\-/_/g;
	eval { return $req->$name };
}
sub uri {
	my($req)= @_;
	$req->{uri} || do {
		require URI;
		my $uri = URI->new;
		my $path= $req->path; $path=~s{^/} [];
		$uri->scheme($req->scheme);
		$uri->host($req->host);
		$uri->port($req->port);
		$uri->path($path);
		$ENV{QUERY_STRING} and $uri->query($ENV{QUERY_STRING});
		$req->{uri}= $uri->canonical;
		$req->{uri};
	 };
}
sub remote_addr { $ENV{REMOTE_ADDR} || '127.0.0.1' }
sub args        { $ENV{QUERY_STRING} || $ENV{REDIRECT_QUERY_STRING} || "" }
sub user_agent  { $ENV{HTTP_USER_AGENT} || "" }
sub protocol    { $ENV{SERVER_PROTOCOL} }
sub user        { $ENV{REMOTE_USER} || "" }
sub method      { $ENV{REQUEST_METHOD} || 'GET' }
sub server_port { $ENV{SERVER_PORT} || 80 }
sub server_name { $ENV{SERVER_NAME} }
sub request_uri { $ENV{REQUEST_URI} || "" }
sub path_info   { $ENV{PATH_INFO} || "" }
sub https       { $ENV{HTTPS} || "" }
sub referer     { $ENV{HTTP_REFERER} || "" }
sub accept_encoding { $ENV{HTTP_ACCEPT_ENCODING} || "" }
sub host { $ENV{HTTP_HOST} || $ENV{SERVER_NAME} || '127.0.0.1' }
sub host_name {
	my($req)= @_;
	$req->{host_name} || do {
		$req->{host_name}= $req->host;
		$req->{host_name}=~s{\:\d+$} [];
		$req->{host_name};
	  };
}
sub remote_host {
	my($req)= @_;
	$req->{remote_host} || do {
		$req->{remote_host}= $ENV{REMOTE_HOST}
		 || gethostbyaddr(pack("C*", split(/\./, $_[0]->remote_addr)), 2)
		 || $_[0]->remote_addr;
		$req->{remote_host};
	 };
}
sub result_status { $_[1] || 403 }

1;

__END__


=head1 NAME

Egg::Request - Exclusive module of WEB request processing.

=head1 SYNOPSIS

 # Access from Egg to this object.
 $e->request  or $e->res;

 # get query.
 my $param= $request->params;
 my $foo= $param->{foo};
   or
 my $foo= $request->param('foo');

 # get cookie string.
 my $cookie= $request->cookie([COOKIE NAME]);
   or
 my $cookie= $request->cookies->{[COOKIE NAME]};
   and
 my $foge= $cookie->value;

 # get request path
 # * / enters the head without fail.
 my $path= $request->path;

 etc..

=head1 DESCRIPTION

 Query parameters are united by the character-code set with $e->config->
 {character_in}.
 If $e->config->{character_in} is undefined, it treats as 'euc'.

=head2 METHODS

$request->r;

* Accessor to object for Request processing.

$request->parameters  or $request->params;

* Request query is returned by the HAHS reference.

$request->param([PARAM NAME]);

* Request query is returned. does general operation.

$request->secure;

* It becomes true at the request to SSL or Port 443.

$request->scheme;

* Scheme of URL is returned.  http or https

$request->path;

* request path is returned.
* / enters the head without fail.

$request->cookie([COOKIE NAME]);

* scalar object of cookie is restored.
* In addition, when the value is taken out, value is used.

$request->cookies;

* HASH reference of Cookie is returned.

$request->header([NAME]);

* It moves like wrapper to the methods such as $request->uri and
  $request->user_agent.
* It is scheduled to change to HTTP::Headers->header here.

$request->uri;

* Request uri assembled by the URI module is returned.

$request->remote_addr  or $request->address;

* $ENV{REMOTE_ADDR} is returned.

$request->args;

* $ENV{QUERY_STRING} の内容をそのまま返します。

$request->user_agent  or $request->agent;

* $ENV{HTTP_USER_AGENT} is returned.

$request->protocol;

* $ENV{SERVER_PROTOCOL} is returned.

$request->user;

* $ENV{REMOTE_USER} is returned.

$request->method;

* $ENV{REQUEST_METHOD} is returned.

$request->server_port  or $request->port;

* $ENV{SERVER_PORT} is returned.

$request->server_name;

* $ENV{SERVER_NAME} is returned.

$request->request_uri;

* $ENV{REQUEST_URI} is returned.

$request->path_info;

* $ENV{PATH_INFO} is returned.

$request->https

* $ENV{HTTPS} is returned.

$request->referer;

* $ENV{HTTP_REFERER} is returned.

$request->accept_encoding;

* $ENV{HTTP_ACCEPT_ENCODING} is returned.

$request->host;

* $ENV{HTTP_HOST} or $ENV{SERVER_NAME} is returned.

$request->host_name;

* Host name of the WEB server is returned.

$request->remote_host;

* $ENV{REMOTE_HOST} is returned.
* When hostname_lookup is off, acquisition is tried by gethostbyaddr().

=head1 SEE ALSO

L<CGI::Cookie>, L<Egg::Response>

=head1 AUTHOR

Masatoshi Mizuno, <lt>L<mizunoE<64>bomcity.com><gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. <L<http://egg.bomcity.com/>>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
