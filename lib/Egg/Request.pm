package Egg::Request;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Request.pm 122 2007-05-10 18:21:18Z lushe $
#

=head1 NAME

Egg::Request - HTTP request processing for Egg.

=head1 SYNOPSIS

  # The request object is obtained.
  my $req= $e->request;
  
  # The query data is acquired.
  my $foo= $req->param('foo');
    or
  my $foo= $req->params->{foo};
  
  # Cookie is acquired.
  my $baa= $req->cookie('baa')->value;
    or
  my $baa= $req->cookie_value('baa');
  
  # The request passing is acquired.
  my $path= $req->path;
  
  # ...etc.

=head1 DESCRIPTION

This module offers processing and the function that relates to the HTTP request.

=head1 CONFIGURATION

=head2 max_snip_deep

Depth of directory that can be requested.

  # If it is 'max_snip_deep = 3', the following request becomes Forbidden.
  
  http://foo.tld/baa/zuu/hoge/bad_content

=head2 request

Option to set or to pass to main body for request.

=over 4

=item * DISABLE_UPLOADS

The file upload is invalidated.

* Please refer to 'Egg::Plugin::Upload' for the file upload.

=item * TEMP_DIR

Work folder for file upload chiefly

=item * POST_MAX

Maximum of standard input accepted when request method is POST.

=back

=cut
use strict;
use warnings;
use CGI::Cookie;
use base qw/Class::Accessor::Fast/;
use Carp qw/croak/;

our $VERSION = '2.01';

__PACKAGE__->mk_accessors(qw/ e r path is_get is_post is_head /);

=head1 METHODS

=head2 r

The object that actually does the request processing is returned.

For instance, if it is Apache::Request, and usual CGI if it is operating
by mod_perl, the object of CGI is restored.

  $request-E<gt>r->param;

* The method that can be used depends on the module of the object because
  it is a direct call.

=head2 path

The request passing is returned.

* There is a thing different from 'PATH_INFO' of the environment variable
  because returned information is processed to process it with Egg.

=head2 is_get

When the request method is GET, ture is restored.

=head2 is_post

When the request method is POST, true is restored.

=head2 is_head

When the request method is HEAD, true is restored.

=head2 http_user_agent

Refer to 'HTTP_USER_AGENT' of the environment variable.

=over 4

=item * Alias: agent, user_agent

=back

=head2 server_protocol

Refer to 'SERVER_PROTOCOL' of the environment variable.

=over 4

=item * Alias: protocol

=back

=head2 remote_user

Refer to 'REMOTE_USER' of the environment variable.

=over 4

=item * Alias: user

=back

=head2 script_name

Refer to 'SCRIPT_NAME' of the environment variable.

=head2 request_uri

Refer to 'REQUEST_URI' of the environment variable.

* A value different from the uri method might return.

=head2 path_info

Refer to 'PATH_INFO' of the environment variable.

=head2 http_referer

Refer to 'HTTP_REFERER' of the environment variable.

=over 4

=item * Alias: referer

=back

=head2 http_accept_encoding

Refer to 'HTTP_ACCEPT_ENCODING' of the environment variable.

=over 4

=item * Alias: accept_encoding

=back

=head2 remote_addr

Refer to 'REMOTE_ADDR' of the environment variable.

=over 4

=item * Alias: addr, address

=back

Default is '127.0.0.1'.

=head2 request_method

Refer to 'REQUEST_METHOD' of the environment variable.

=over 4

=item * Alias: method

=back

Default is 'GET'.

=head2 server_name

Refer to 'SERVER_NAME' of the environment variable.

Default is 'localhost'.

=head2 server_software

Refer to 'SERVER_SOFTWARE' of the environment variable.

Default is 'cmdline'.

=head2 server_port

Refer to 'SERVER_PORT' of the environment variable.

=over 4

=item * Alias: port

=back

Default is '80'.

=cut
{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	for ( qw{ HTTP_USER_AGENT SERVER_PROTOCOL REMOTE_USER
	  SCRIPT_NAME REQUEST_URI PATH_INFO HTTP_REFERER HTTP_ACCEPT_ENCODING },
	  [qw{ REMOTE_ADDR 127.0.0.1 }], [qw{ REQUEST_METHOD GET }],
	  [qw{ SERVER_NAME localhost }], [qw{ SERVER_SOFTWARE cmdline }],
	  [qw{ SERVER_PORT 80 }] ) {
		my($key, $accessor, $default)=
		   ref($_) ? ($_->[0], lc($_->[0]), $_->[1]): ($_, lc($_), "");
		*{__PACKAGE__."::$accessor"}= sub { $ENV{$key} || $default };
	}
  };

*agent    = \&http_user_agent;  *user_agent = \&http_user_agent;
*protocol = \&server_protocol;  *user       = \&remote_user;
*method   = \&request_method;   *port       = \&server_port;
*addr     = \&remote_addr;      *address    = \&remote_addr;
*referer  = \&http_referer;     *url        = \&uri;
*params   = \&parameters;       *accept_encoding = \&http_accept_encoding;

=head2 mp_version

The version of the mod_perl is returned if it operates by mod_perl.

=cut
my $MP_VERSION= 0;
sub mp_version { $MP_VERSION }

sub _startup {
	my($class, $e)= @_;
	my $mp_util= 'ModPerl::VersionUtil';

	my $r_class= $e->global->{REQUEST_PACKAGE}=
	     $ENV{ $e->uc_namespace. '_REQUEST_CLASS'}
	  || $e->config->{request_class}
	  || do {
		($ENV{MOD_PERL} and $mp_util->require) ? do {
			$MP_VERSION= $mp_util->mp_version;
			  $MP_VERSION > 2   ? 'Egg::Request::Apache::MP20'
			: $mp_util->is_mp2  ? 'Egg::Request::Apache::MP20'
			: $mp_util->is_mp19 ? 'Egg::Request::Apache::MP19'
			: $mp_util->is_mp1  ? 'Egg::Request::Apache::MP13'
			: do {
				$MP_VERSION= 0;
				warn qq{ Unsupported mod_perl v$MP_VERSION };
				'Egg::Request::CGI';
			  };
		  }: do {
			'Egg::Request::CGI';
		  };
	  };

	$r_class->require or die $@;
	my $get_params;
	if (my $code= $r_class->can('_prepare_params')) {
		$get_params= $code;
	} else {
		$get_params= sub {
			my %params;
			$params{$_}= $_[0]->r->param($_) for $_[0]->r->param;
			\%params;
		  };
	}
	no warnings 'redefine';
	*parameters= sub { $_[0]->{parameters} ||= $get_params->(@_) };

	$r_class->_setup_output($e);
	$r_class->_setup_handler($e);

	$e->debug_out("# + $e->{namespace} - Request Class : $r_class");
	$r_class;
}
sub _setup_output {
	my($class, $e)= @_;
	no warnings 'redefine';
	*Egg::Response::output= sub {
		my $res = shift;
		my $head= shift || croak q{ I want response header. };
		my $body= shift || croak q{ I want response body.   };
		CORE::print STDOUT $$head, ($$body || "");
	  };
	@_;
}
sub _setup_handler {
	my($class, $e)= @_;
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{"$e->{namespace}::handler"}=
	   $e->can('run') || die q{ $e->run is not found. };
	@_;
}

=head2 new

Constructor. When the project is usually started, this is called.
It is not necessary to call it specifying it.

=cut
sub new {
	my($class, $r, $e)= @_;
	my $req= bless { e=> $e, r=> $r }, $class;

	@{$req}{qw{ is_get is_post is_head }}=
	    $req->method=~/^GET/  ? (1, 0, 0)
	  : $req->method=~/^POST/ ? (0, 1, 0)
	  : $req->method=~/^HEAD/ ? (0, 0, 1)
	  :                         (1, 0, 0);

	my $path;
	if ($ENV{REDIRECT_URI}) {
		$path= $ENV{PATH_INFO} || $ENV{REDIRECT_URI} || '/';
	} else {
		$path = $ENV{SCRIPT_NAME} || "";
		$path =~s{/+$} [];
		$path.= $ENV{PATH_INFO} if $ENV{PATH_INFO};
	}
	$req->path( $path=~m{^/} ? $path: "/$path" );

	# Request parts are generated.
	$path=~s#\s+##g; $path=~s#^/+##; $path=~s#/+$##;
	my @snip= split /\/+/, $path;
	my $max;
	if ($max= $e->config->{max_snip_deep} and $max< scalar(@snip)) {
		$e->finished(403);
	} else {
		$req->{snip}= \@snip;
	}
	$req;
}

=head2 snip ( [PARTS_NUMBER] )

The ARRAY reference for which $request-E<gt>path is resolved by '/' delimitation
is returned.

* The depth of passing that can be requested by 'max_snip_deep' of configuration
  can be setup.  Default is undefined.

=cut
sub snip {
	my $req= shift;
	@_ ? ($req->{snip}[$_[0]] || ""): $req->{snip};
}

=head2 parameters

The request query is returned by the HASH reference.

=over 4

=item * Alias: params

=back

  while (my($key, $value)= each %{$request->params}) {
    print "$key = $value \n";
  }

=head2 param ( [KEY], [VALUE] )

When the argument is omitted, the key list of the request query is returned
with ARRAY.

When KEY is specified, the value of the corresponding request query is returned.

When both KEY and VALUE are given, the value is set.

  my $value= $request->param('param_name');
  
  $request->param( in_param => 'in_value' );

=cut
sub param {
	my $req= shift;
	return keys %{$req->parameters} unless @_;
	my $key= shift;
	@_ ? $req->parameters->{$key}= shift : $req->parameters->{$key};
}

=head2 cookie ( [KEY] )

Cookie corresponding to KEY is returned.

Because it is an object that is returned that CGI::Cookie returns, it is
necessary to use the value method to refer to the value in addition.
see L<CGI::Cookie>,

  my $cookie= $request->cookie('get_param');
  
  my $value = $cookie->value;

=cut
sub cookie {
	my $req= shift;
	my $cookie= $req->cookies;
	return keys %$cookie if @_== 0;
	($_[0] && exists($cookie->{$_[0]})) ? $cookie->{$_[0]}: undef;
}

=head2 cookies

Fetch of L<CGI::Cookie > is returned. * It is HASH reference that returns.

  my $cookies = $request->cookies;
  
  while (my($key, $cookie)= each %$cookies) {
  	print "$key = ". $cookie->value ."\n";
  }

=cut
sub cookies {
	my($req)= @_;
	$req->{cookies} ||= do { fetch CGI::Cookie || {} };
}

=head2 cookie_value ( [KEY] )

Caene of the value method of Cookie corresponding to KEY is returned.
$request-E<gt>cookie([KEY])->value is done in a word at a time.

  my $value= $request->cookie_value('cookie_name');

=cut
sub cookie_value {
	my $req= shift;
	my $key= shift || return "";
	my $cookie= $req->cookies->{$key} || return "";
	$cookie->value || "";
}

=head2 secure

True is returned concluding that the SSL communication is done when HTTPS
of the environment variable is effective or 'SERVER_PORT' is 443.

=cut
sub secure {
	$_[0]->{secure} ||= (
	     ($ENV{HTTPS} && lc($ENV{HTTPS}) eq 'on')
	  || ($ENV{SERVER_PORT} && $ENV{SERVER_PORT}== 443)
	  ) ? 1: 0;
}

=head2 scheme

If $request-E<gt>secure is true,
'Https' is returned though 'Http' returns usually.

=cut
sub scheme {
	$_[0]->{scheme} ||= $_[0]->secure ? 'https': 'http';
}

=head2 uri

The result of assembling URI based on $request-E<gt>path is returned.

=over 4

=item * Alias: url

=back

=cut
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

=head2 remote_host

If environment variable 'REMOTE_HOST' is obtained, the value is returned.
If it is not good, gethostbyaddr is called and acquisition is tried.
Finally, $request-E<gt>remote_addr is returned.

=cut
sub remote_host {
	my($req)= @_;
	$req->{remote_host} ||= do {
		$ENV{REMOTE_HOST}
		 || gethostbyaddr(pack("C*", split(/\./, $req->remote_addr)), 2)
		 || $req->remote_addr;
	 };
}

=head2 host_name

As for the value that $request-E<gt>host returns, the port number is sometimes
included.  This method returns the host name that doesn't contain the port
number without fail.

=cut
sub host_name {
	my($req)= @_;
	$req->{host_name} ||= do {
		my $host= $req->host;
		$host=~s{\:\d+$} [];
		$host;
	  };
}

=head2 host

'HTTP_HOST' of the environment variable or 'SERVER_NAME' is returned.

Default is 'localhost',

=cut
sub host { $ENV{HTTP_HOST}    || $ENV{SERVER_NAME} || 'localhost' }

=head2 args

The value of 'QUERY_STRING' of the environment variable or 'REDIRECT_QUERY_STRING'
is returned.

=cut
sub args { $ENV{QUERY_STRING} || $ENV{REDIRECT_QUERY_STRING} || "" }

=head2 response

It is an accessor to the Egg::Response object.

=cut
sub response { $_[0]->{response} ||= $_[0]->e->response }

=head1 SEE ALSO

L<CGI::Cookie>,
L<Egg::Request::CGI>
L<Egg::Request::FastCGI>
L<Egg::Response>,
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
