package Egg::Helper::BlankPage;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: BlankPage.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Helper::BlankPage - Default page for project.

=head1 SYNOPSIS

  require Egg::Helper::BlankPage;
  
  $e->response->body( Egg::Helper::BlankPage->out($e) );

=head1 DESCRIPTION

The screen display of the default immediately after generation of the project
is supported.

=cut
use strict;
use warnings;
use Egg::Release;

our $VERSION= '2.00';

=head1 METHODS

=head2 out ( [PROJECT_OBJ] )

The default screen is returned.

The sample code of dispatch is acquired from '_example_code' method
of the Dispatch module.

  my $body= Egg::Helper::BlankPage->out($e);

=cut
sub out {
	my($dispatch, $e)= @_;
	my $version; eval{ $version= $e->VERSION };
	my $d_class= ref($e->dispatch);
	   $d_class=~s{\:+handler$} [];

	my $a= {
	  project_name    => $e->namespace,
	  project_version => ($version || '*.**'),
	  static_uri      => $e->config->{static_uri},
	  request_path    => $e->request->path,
	  example_code    => $e->dispatch->_example_code,
	  dispatch_class  => $d_class,
	  };

	<<END_OF_HTML;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<title>$a->{project_name}-$a->{project_version}</title>
<head>
<style type="text/css">
body {
	background     : #817264;
	text-align     : center;
	}
a {
	color          : #07F;
	}
img {
	border         : 0px;
	}
h1, h2, h3 {
	margin         : 5px;
	font           : bold 25px Times,sans-serif;
	text-decoration: underline;
	}
h1 {
	float          : left;
	}
h2, h3 {
	font-size      : 14px;
	}
h2 {
	margin         : 30px 5px 0px 10px;
	clear          : both;
	color          : #777;
	text-align     : left;
	}
h3 {
	margin-top     : 0px;
	color          : #C99158;
	}
ul {
	margin         : 2px 2px 2px 350px;
	text-align     : left;
	font-size      : 14px;
	}
pre {
	margin         : 2px 10px 5px 10px;
	padding        : 10px;
	background     : #FFF7E5;
	font           : normal 14px sans-serif;
	border         : #C99158 solid 1px;
	}
#shadow {
	width          : 640px;
	padding:0px    : 0px;
	margin         : 0px auto 0px auto;
	border         : 0px;
	border-right   : #000000 solid 2px;
	border-bottom  : #000000 solid 2px;
	}
#container {
	background     : #FFFFFF;
	border         : #FFEB00 solid 5px;
	}
#container {
	text-align     : center;
	}
#banner {
	height         : 40px;
	text-align     : left;
	font           : bold 10px Times,sans-serif;
	}
#banner img {
	margin         : 7px;
	float          : left;
	}
#banner .pathinfo {
	background     : #FFF7E9;
	margin         : 2px 5px 2px 240px;
	padding        : 2px 2px 2px 7px;
	font-size      : 14px;
	border         : #FF8F00 solid 2px;
	}
#content {
	margin         : 10px;
	padding        : 10px;
	border         : #DDDDDD solid 1px;
	}
#content .box {
	margin-top     : 10px;
	padding        : 7px;
	text-align     : left;
	}
</style>
</head>
<body>
<div id="shadow"><div id="container">
<div id="banner">
<img src="$a->{static_uri}images/egg224x33.gif" width="224" height="33" alt="Egg - WEB application framework." />
Request PATH:
<div class="pathinfo">$a->{request_path}</div>
</div>
<div id="content">
<h1>&nbsp; BLANK PAGE &nbsp;</h1>
<ul>
<li><a target="_blank" href="http://search.cpan.org/dist/Egg-Release/">Refer to CPAN.</a></li>
<li><a target="_blank" href="$Egg::Release::DISTURL">Original distribution site.</a></li>
</ul>
<h2>Project name and version - $a->{project_name}-$a->{project_version}</h2>
<div class="box">
<h3>Example of dispatch code. &nbsp; for $a->{dispatch_class}.</h3>
<pre><tt>$a->{example_code}</tt></pre>
</div>
<a target="_blank" href="$Egg::Release::DISTURL">
<img src="$a->{static_uri}images/egg468x60.gif" width="468" height="60" alt="Powerd by Egg." /></a>
</div>
</div></div>
</body>
</html>
END_OF_HTML

}

=head1 SEE ALSO

L<Egg::Dispatch>
L<Egg::Dispatch::Fast>
L<Egg::Dispatch::Standard>
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