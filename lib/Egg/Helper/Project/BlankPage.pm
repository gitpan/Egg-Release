package Egg::Helper::Project::BlankPage;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: BlankPage.pm 245 2007-02-24 18:21:27Z lushe $
#
use strict;

our $VERSION= '0.02';

sub out {
	my($dispatch, $e)= @_;
	my $a= {
	  project_name  => $e->namespace,
	  origin_site   => 'http://egg.bomcity.com/',
	  static_uri    => $e->config->{static_uri},
	  request_path  => $e->request->path,
	  dispatch_class=> $e->dispatch_calss,
	  example_code  => $e->dispatch->_example_code,
	  };
	eval { $a->{project_version}= $e->VERSION };
	$a->{project_version} ||= '*.**';
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
<li><a target="_blank" href="$a->{origin_site}">Original distribution site.</a></li>
</ul>
<h2>Project name and version - $a->{project_name}-$a->{project_version}</h2>
<div class="box">
<h3>Example of dispatch code. &nbsp; for $a->{dispatch_class}.</h3>
<pre><tt>$a->{example_code}</tt></pre>
</div>
<a target="_blank" href="$a->{origin_site}">
<img src="$a->{static_uri}images/egg468x60.gif" width="468" height="60" alt="Powerd by Egg." /></a>
</div>
</div></div>
</body>
</html>
END_OF_HTML
}

1;

__END__

=head1 NAME

Egg::Helper::Project::BlankPage - A module to offer the page of the blank of default for Egg.

=head1 SEE ALSO

L<Egg::Helper>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
