
use Test::More qw/no_plan/;
use Egg::Helper;
eval{ use HTML::Mason };
plan skip_all => "HTML::Mason required for testing plugin." if $@;

my $t= Egg::Helper->run('O:Test');

my $run_modes= <<END_OF_RUN;
  _default=> sub {},
END_OF_RUN

my @creates= $t->yaml_load( join '', <DATA> );

$t->prepare(
  mason_ok=> 1,
  dispatch=> { run_modes=> $run_modes },
  create_files=> \@creates,
  );

$ENV{REMOTE_ADDR}= '127.0.0.1';

ok( my $e= $t->egg_virtual );
ok( my $CRLF= $Egg::CRLF );
ok( $e->is_view('Mason') );
ok( my $view= $e->view );
isa_ok $view, 'Egg::View::Mason';
ok( $view->param( page_title => 'test_page' ) );
ok( $view->params->{page_title} eq 'test_page' );

if (my $catch= $t->response_catch($e)) {
	like $$catch, qr#\bContent\-Type\:\s+text/html[^\r\n]*$CRLF#s;
	like $$catch, qr#<html>.+?</html>#s;
	like $$catch, qr#<head>.+?</head>#s;
	like $$catch, qr#<title>test_page</title>#s;
	like $$catch, qr#<h1>127\.0\.0\.1</h1>#s;
}

1;

__DATA__
---
filename: root/index.tt
value: |
  <html>
  <head>
  <title><% $p->{page_title} %></title>
  </head>
  <body>
  <h1><% $e->request->address %></h1>
  </body>
  </html>
