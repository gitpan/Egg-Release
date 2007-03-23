package Egg::Request;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Request.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use base qw/Egg::Component/;
use CGI::Cookie;
no warnings 'redefine';

__PACKAGE__->mk_accessors( qw/r debug path/ );

our $VERSION= '0.12';

*address= \&remote_addr;
*port   = \&server_port;
*agent  = \&user_agent;

{
	no strict 'refs';  ## no critic
	for my $method (qw/post get/) {
		*{__PACKAGE__."::is_$method"}= sub {
			$_[0]->{"is_$method"} ||= $_[0]->method=~/^$method/i ? 1: 0;
		  };
	}
  };

sub setup {
	my($class, $e)= @_;
	$e->config->{request} ||= {};
	my $base= $e->namespace;
	no strict 'refs';  ## no critic
	*{"Egg::handler"}= sub { shift; $base->run(@_) };
	@_;
}
sub new {
	my $class= shift;
	my $e= shift || Egg::Error->throw('I want Egg object.');
	my $r= shift || undef;
	my $req= $class->SUPER::new($e);
	$req->{r} = $r;
	$req->{args}= {};
	$req->{debug}= $e->debug;
	$req;
}
sub cookie {
	my $req= shift;
	my $cookie= $req->cookies;
	return keys %$cookie if @_== 0;
	($_[0] && exists($cookie->{$_[0]})) ? $cookie->{$_[0]}: undef;
}
sub cookies {
	my($req)= @_;
	$req->{cookies} ||= do { fetch CGI::Cookie || {} };
}
sub cookie_value {
	my $req= shift;
	my $key= shift || return(undef);
	my $cookie= $req->cookies->{$key} || return(undef);
	$cookie->value || "";
}
sub prepare_params {
	my($req)= @_;
	$req->{params}{$_}= $req->r->param($_) for $req->r->param;
}
sub prepare {
	my($req)= @_;
	my $config= $req->e->config;

	my $path= $ENV{REDIRECT_URI} ? do {
		$ENV{PATH_INFO} || $ENV{REDIRECT_URI} || '/';
	  }: do {
		my $tmp= $ENV{SCRIPT_NAME} || '/';
		$ENV{PATH_INFO} ? "$tmp$ENV{PATH_INFO}": $tmp;
	  };
	$req->path( $path=~m{^/} ? $path: "/$path" );

	$req->create_snip($path, $config->{max_snip_deep}) || return 0;
	$req->prepare_params;
	1;
}
sub create_snip {
	my $req = shift;
	my $path= shift || "";
	my $max = shift || return 0;
	$path=~s#\s+##g; $path=~s#^/+##; $path=~s#/+$##; $path=~s#//+#/#g;
	my @snip= split /\//, $path;
	scalar(@snip)> $max ? 0: $req->e->snip(\@snip);
}
sub header {
	my $req = shift;
	my $name= lc(shift) || return "";
	$name=~s/\-/_/g;
	eval { return $req->$name };
}
sub secure {
	my($req)= @_;
	$req->{secure}
	 ||= (($ENV{HTTPS} && lc($ENV{HTTPS}) eq 'on')
	   || ($ENV{SERVER_PORT} && $ENV{SERVER_PORT}== 443)) ? 1: 0;
}
sub scheme {
	my($req)= @_;
	$req->{scheme} ||= $req->secure ? 'https': 'http';
}
sub uri {
	my($req)= @_;
	$req->{uri} ||= do {
		require URI;
		my $uri = URI->new;
		my $path= $req->path; $path=~s{^/} [];
		$uri->scheme($req->scheme);
		$uri->host($req->host);
		$uri->port($req->port);
		$uri->path($path);
		$ENV{QUERY_STRING} and $uri->query($ENV{QUERY_STRING});
		$uri->canonical;
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
sub script_name { $ENV{SCRIPT_NAME} || "" }
sub request_uri { $ENV{REQUEST_URI} || "" }
sub path_info   { $ENV{PATH_INFO} || "" }
sub https       { $ENV{HTTPS} || "" }
sub referer     { $ENV{HTTP_REFERER} || "" }
sub accept_encoding { $ENV{HTTP_ACCEPT_ENCODING} || "" }
sub host { $ENV{HTTP_HOST} || $ENV{SERVER_NAME} || '127.0.0.1' }
sub host_name {
	my($req)= @_;
	$req->{host_name} ||= do {
		my $host= $req->host;
		$host=~s{\:\d+$} [];
		$host;
	  };
}
sub remote_host {
	my($req)= @_;
	$req->{remote_host} ||= do {
		$ENV{REMOTE_HOST}
		 || gethostbyaddr(pack("C*", split(/\./, $req->remote_addr)), 2)
		 || $req->remote_addr;
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

Query parameters are united by the character-code set with $e->config->{character_in}.

If $e->config->{character_in} is undefined, it treats as 'euc'.

=head1 METHODS

=head2 $request->r;

Accessor to object for Request processing.

=head2 $request->parameters  or $request->params;

Request query is returned by the HAHS reference.

=head2 $request->param([PARAM NAME]);

Request query is returned. does general operation.

=head2 $request->create_snip([PATH]);

It tries to make $e->snip.

example of dispatch.

 $e->request->create_snip( $e->request->param('path') );
 
 my $dir= $e->snip->[0] || return qw{ Root };
 
 ... ban, ban, ban.

=head2 $request->secure;

It becomes true at the request to SSL or Port 443.

=head2 $request->scheme;

Scheme of URL is returned.  http or https

=head2 $request->path;

request path is returned. '/' enters the head without fail.

=head2 $request->cookie([COOKIE NAME]);

scalar object of cookie is restored.

In addition, when the value is taken out, value is used.

=head2 $request->cookies;

HASH reference of Cookie is returned.

=head2 $request->cookie_value ([COOKIE NAME])

The cookie is received, and the content of the specified key is returned.

  if (my $value= $request->cookie_value('foo')) {
    ... It succeeded in the receipt.
  }

=head2 $request->header([NAME]);

It moves like wrapper to the methods such as $request->uri and $request->user_agent.

It is scheduled to change to HTTP::Headers->header here.

=head2 $request->uri;

Request uri assembled by the URI module is returned.

=head2 $request->remote_addr  or $request->address;

$ENV{REMOTE_ADDR} is returned.

=head2 $request->args;

$ENV{QUERY_STRING} is returned.

=head2 $request->user_agent  or $request->agent;

$ENV{HTTP_USER_AGENT} is returned.

=head2 $request->protocol;

$ENV{SERVER_PROTOCOL} is returned.

=head2 $request->user;

$ENV{REMOTE_USER} is returned.

=head2 $request->method;

$ENV{REQUEST_METHOD} is returned.

=head2 $request->is_post

When $request->method is POST, it becomes ture.

=head2 $request->is_get

When $request->method is GET, it becomes ture.

=head2 $request->server_port  or $request->port;

$ENV{SERVER_PORT} is returned.

=head2 $request->server_name;

$ENV{SERVER_NAME} is returned.

=head2 $request->request_uri;

$ENV{REQUEST_URI} is returned.

=head2 $request->path_info;

$ENV{PATH_INFO} is returned.

=head2 $request->https

$ENV{HTTPS} is returned.

=head2 $request->referer;

$ENV{HTTP_REFERER} is returned.

=head2 $request->accept_encoding;

$ENV{HTTP_ACCEPT_ENCODING} is returned.

=head2 $request->host;

$ENV{HTTP_HOST} or $ENV{SERVER_NAME} is returned.

=head2 $request->host_name;

Host name of the WEB server is returned.

=head2 $request->remote_host;

$ENV{REMOTE_HOST} is returned.

When hostname_lookup is off, acquisition is tried by gethostbyaddr().

=head1 SEE ALSO

L<CGI::Cookie>,
L<Egg::Response>
L<Egg::Release>

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
