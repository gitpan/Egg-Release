package Egg::Debug::Base;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base.pm 48 2007-03-21 02:23:43Z lushe $
#
use strict;
use warnings;
use Carp qw/confess/;
use Egg::Release;

our $VERSION= '0.05';

sub debug_report {
	my($class, $e)= @_;
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
sub debug_out {
	my $class= shift;
	my $e    = shift || confess q/I want Egg object./;
	my $msg  = shift || confess q/The message is not specified./;
	$msg=~s/[\r\n]+$//;
	print STDERR "$msg\n";
}
sub disp_error {
	my $class= shift;
	my $e    = shift;
	my $err  = shift || return 0;
	$err=~s{(?:\r?\n|\r)} [<br />\n]sg;
	my $res= $e->response;
	my $eggver= "Egg::Release v". Egg::Release->VERSION;
	my $myname= $e->namespace. ' v'. $e->VERSION;
	my $clang = $e->config->{content_language} || 'en';
	my $ctype = $e->config->{content_type} || 'text/html';
	my $querys= "";
	$e->request->param and do {
		my $params= $e->request->params;
		$querys = q{<div class="querys"><b>Request Querys:</b>}
		        . q{<table>};
		for (keys %$params) {
			my $value= $params->{$_} || "";
			($value && ! ref($value)) and do {
				$value= $e->escape_html($value);
				$value=~s{(?:\r?\n|\r)} [<br />]sg;
			 };
			$querys.= q{<tr><th>}
			. $e->escape_html($_). qq{</th><td>$value</td></tr>\n};
		}
		$querys.= q{</table></div>}
	 };
	my $body= <<END_OF_DISP;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="$clang">
<head>
<meta http-equiv="content-language" content="$clang" />
<meta http-equiv="Content-Type" content="$ctype" />
<meta http-equiv="Content-Style-Type" content="text/css" />
<title>Error.</title>
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
<h1>$myname</h1>
<div id="content">$err$querys</div>
<div id="footer">
<a href="http://egg.bomcity.com/" target="_blank">
Powered by <strong>$eggver</strong></a>
</div>
</div>
</body></html>
END_OF_DISP
	$res->body(\$body);
	$res->no_cache(1);
	$res->clear; $res->cookies({});
	$res->header('X-Egg-'. $e->namespace. '-ERROR'=> 'true');
	$e->finished(0);
	$e->output_content;
	return 0;
}

1;

__END__

=head1 NAME

Egg::Debug::Base - Debug report from Egg etc.

=head1 SYNOPSIS

$e->debug_out([REPORT TEST]);

=head1 DESCRIPTION

The error screen is built and displayed.

=head1 METHODS

=head2 $e->debug_out([REPORT TEST]);

The message passed to STDERR when Egg operates by debug mode is output.

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Debug::SimpleBench>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
