package Egg::Plugin::Debugging::Screen;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Screen.pm 154 2007-05-17 03:01:31Z lushe $
#
use strict;
use warnings;
use Egg::Release;

our $VERSION = '2.01';

=head1 NAME

Egg::Plugin::Debugging::Screen - Exception is generated, the debugging screen is output.

=head1 DESCRIPTION

The screen of the exception generation is output.

This module is read from L<Egg::Plugin::Debugging>.

=head1 METHODS

=head2 output

The debugging screen is made and $e-E<gt>_finalize_output is done.

* It is always $e-E<gt>finished(0).

* $e-E<gt>response-E<gt>clear is always done.

* It always outputs it with $e-E<gt>response-E<gt>no_cache(1).

* 'X-Egg-[PROJECT_NAME]-ERROR: true' is added to the response header.

=cut
sub output {
	my $debug= shift;
	my($e, $res)= ($debug->{e}, $debug->{e}->response);
	$e->finished(0);
	$res->clear;
	$res->no_cache(1);
	$res->headers->{"X-Egg-$e->{namespace}-ERROR"}= 'true';
	$res->body( _content($e, $res) );
	$e->_finalize_output;
}

sub _content {
	my($e, $res)= splice @_, 0, 2;
	my $err= $e->errstr || 'Internal Error.';

	my $content_language = $e->config->{content_language} || 'en';
	my $content_type     = $e->config->{content_typ}      || 'text/html';
	my $my_version       = "$e->{namespace} v". $e->VERSION;
	my $egg_version      = "Egg::Release v". Egg::Release->VERSION;

	my($querys, $param)= ("");
	if ($param= $e->request->params and %$param) {
		$querys = q{<div class="querys"><b>Request Querys:</b><table>};
		while (my($key, $value)= each %$param) {
			$querys.= q{<tr><th>}. _escape($key). qq{</th>};
			$value= _escape($value) unless ref($value);
			$querys.= qq{<td>$value</td></tr>\n};
		}
		$querys.= q{</table></div>};
	}

	$res->content_language($content_language);
	$res->content_type($content_type);
	$err=~s{\n} [<br />\n]sg;

	<<END_OF_DISP;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="$content_language">
<head>
<meta http-equiv="content-language" content="$content_language" />
<meta http-equiv="Content-Type" content="$content_type" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<meta name="robots" content="noindex,nofollow,noarchive" /> 
<title>EGG - Error.</title>
<style type="text/css">
body {
	background:#FFF376;
	margin:0px;
	text-align:center;
	}
h1 {
	margin:0px; padding:1px 3px 1px 10px;
	font:bold 16pt Times,sans-serif;
	background:#FFBF00;
	border:#B7974E solid 2px; border-bottom:0px;
	}
#container {
	margin:10px auto 0px auto; padding:0px;
	width:720px;
	text-align:left;
	}
#content {
	background:#FFF;
	margin:0px; padding:10px;
	border-right:#B7974E solid 2px; border-left:#B7974E solid 2px;
	text-align:left;
	}
#content .querys {
	margin:10px; padding:2px;
	background:#F9D787; color:#555;
	border:#333 solid 1px;
	font-size:10px;
	}
#content .querys table {
	width:99.5%;
	border-collapse:collapse;
	font-size:12px; color:#000;
	}
#content .querys table th, #content .querys table td {
	padding:2px 3px 1px 5px;
	border-bottom:#C5AB6A solid 1px;
	}
#content .querys table th { background:#FFF1B9 }
#content .querys table td { background:#FFFFED }
#footer {
	background:#FFBF00;
	border:#B7974E solid 2px; border-top:0px;
	font:italic 10pt Times,sans-serif;
	text-align:right;
	}
#footer a { color:#000 }
</style>
</head>
<body>
<div id="container">
<h1>$my_version</h1>
<div id="content"> $err $querys </div>
<div id="footer">
<a href="http://egg.bomcity.com/" target="_blank">
Powered by <strong>$egg_version</strong></a>
</div>
</div>
</body></html>
END_OF_DISP
}
sub _escape {
	my $str= shift || return "";
	my $rep= { '<'=> '&lt;', '>'=> '&gt;', '"'=> '&quot;' };
	$str=~s{([<>\"])} [$rep->{$1}]sg;
	$str=~s{(?:\r?\n|\r)} [<br />]sg;
	$str;
}

=head1 SEE ALSO

L<Egg::Debugging>,
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
