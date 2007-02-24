
use Test::More qw/no_plan/;
use Egg::Helper;
my $t= Egg::Helper->run('O:Test');
$t->prepare( controller=> { egg=> [qw/Redirect::Page/] } );

ok( my $e= $t->egg_virtual );
ok( $e->can('redirect_page') );
ok( $e->prepare_component );
ok( $e->redirect_page('/test', 'test_ok',
  { wait=> 5, alert=> 1, onload_func=> 'start_func' }) );

if (my $catch= $t->response_catch2($e)) {
	like $$catch, qr#<html.*?>.+?</html>#s;
	like $$catch, qr#<meta.+?http\-equiv=\"refresh\".+?content=\"5\;url=/test\".+?/>#s;
	like $$catch, qr#<script.+?window\.onload=\s*alert.+?\;.+?</script>#s;
	like $$catch, qr#<body.+?onload=\"start_func\".*?>#s;
	like $$catch, qr#<h1>test_ok</h1>#s;
}
