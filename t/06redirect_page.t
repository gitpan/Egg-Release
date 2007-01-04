
use Test::More tests => 14;
use lib 't';
use EggTest;
my $e = new EggTest;
my $res= $e->response;
my $out;

#0
ok( $res->redirect_page('/redirect', 'OK') );
ok( $out= $res->body );
ok( $res->status );
ok( $res->status== 200 );
like( $res->content_type, qr{^text/html} );

#5
like( $$out, qr{<html.*?>.+?</html>}is );
like( $$out, qr{<head.*?>.+?</head>}is );
like( $$out, qr{<body.*?>.+?</body>}is );
ok( &html_check_refresh($$out, '/redirect') );
like( $$out, qr{<h1>\s*OK\s*</h1>}s );

#10
ok( $res->redirect_page('/redirect', 'OK2', { alert=> 1 }) );
ok( $out= $res->body );
ok( &html_check_jsalert($$out) );
like( $$out, qr{<h1>\s*OK2\s*</h1>}s );

sub html_check_refresh {
	my $html= shift || return 0;
	my $url = shift || return 0;
	if (my($opt)= $html=~m{<meta\s+(.*?http\-equiv=\"refresh\".*?)>}is) {
		return 1 if $opt=~m{content=\"\d+\;url=$url\"}s;
	}
	return 0;
}
sub html_check_jsalert {
	my $html= shift || return 0;
	if (my($js)= $html=~m{<script\s+type=\"text/javascript\">(.+?)</script>}is) {
		return 1 if $js=~m{window\.onload\s*\=\s*alert\(.+?\)\s*\;}s;
	}
	return 0;
}
