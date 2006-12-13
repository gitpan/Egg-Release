package Egg::Helper::Welcom;
#
# Copyright 2006 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id$
#
use strict;
use Egg::Release;

our $VERSION= '0.01';

sub egg_url {
	"http://egg.bomcity.com";
}
sub title {
	my($class, $e)= @_;
	my $egg_var= Egg::Release->VERSION;
	"WELCOM / Egg::Release Ver.$egg_var - WEB Application Framework.";
}
sub project {
	my($class, $e)= @_;
	my $my_name= $e->namespace;
	my $my_ver = $e->VERSION;
	"Project Name: $my_name Ver.$my_ver";
}
sub label {
	"Egg-v". Egg::Release->VERSION;
}
sub style {
	my($class, $e)= @_;
	<<END_OF_STYLE;
body {
	margin:0px;
	background:#FFF;
	font:normal 10pt sans-serif;
	text-align:center;
	}
img {
	border:0px;
	}
h1 {
	margin:0px; padding:2px 10px 2px 10px;
	font:bold 13pt sans-serif;
	background:#D7AF36; color:#FFF;
	text-align:left;
	border-bottom:#A56800 solid 1px;
	}
p {
	margin:0px 0px 10px 0px;
	}
pre {
	margin:10px 10px 10px 5px; padding:5px;
	background:#FDF9ED;
	border:#E1D17C solid 1px;
	border-left:#FF9100 solid 2px;
	border-right:0px;
	}
#container {
	width:720px;
	border:#EEE solid 1px;
	margin:0px auto 30px auto;
	padding:0px;
	}
#banner {
	height:75px;
	}
#banner img {
	float:left;
	}
#banner div {
	margin-left:240px;
	padding:10px;
	text-align:left;
	font:bold 11pt sans-serif;
	}
#project {
	margin:0px; padding:1px 10px 1px 10px;
	text-align:left;
	background:#E1D17C;
	font:bold 10pt sans-serif;
	}
#content {
	margin:0px; padding:15px;
	border:#E1D17C solid 7px;
	border-top:0px;
	text-align:left;
	}
#content .footbanner {
	margin-top:25px;
	text-align:center;
	}
#footer {
	clear:both;
	padding:7px 3px 3px 3px;
	background:#FFF9E9;
	border:#E1D17C solid 1px;
	border-top:#A56800 solid 1px;
	}
#footer .info {
	padding-left:40px;
	font-size:10px;
	}
END_OF_STYLE
}
sub footer {
	my $url= &egg_url;
	<<END_OF_FOOTER;
<div id="footer">
<a href="$url" target="_blank">
<img src="/images/egg468x60.gif" width="468" height="60" alt="Egg - WEB application framework." /></a>
<div class="info">* Banner for link. Please use it.</div>
</div>
END_OF_FOOTER
}

1;

__END__

=head1 NAME

Egg::Helper::Welcom - Default page immediately after project.

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
