
use Test::More tests=> 12;
use FileHandle;
use lib 't';
use Egg::Helper::Test;
use EggTest;
my $et = new Egg::Helper::Test;
my $e  = new EggTest;
my $tmp= $et->temp;

$ENV{REMOTE_ADDR}= '192.168.100,100';

#0
ok( $e->is_view('Template') );
ok( my $view= $e->view );
ok( ref($view) eq 'Egg::View::Template' );
ok( $view->param('page_title'=> 'test_page') );
ok( $e->template('template.tmpl') );

#5
ok( $view->output($e) );
ok( my $body= $e->response->body );
ok( $$body );
like( $$body, qr{<html>.+?</html>}s );
like( $$body, qr{<body>.+?</body>}s );

#10
like( $$body, qr{<h1>test_page</h1>}s );
like( $$body, qr{<strong>192\.168\.100\,100</strong>}s );

