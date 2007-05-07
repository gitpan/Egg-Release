
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new;
$test->prepare( create_files => [ $test->yaml_load( join '', <DATA> ) ] );

my $e= $test->egg_pcomp_context;

ok my $view= $e->view('Template');
isa_ok $view, 'Egg::View::Template';
can_ok $view, qw/ new output
  render filter associate _setup _push_var _create_option /;
ok my $conf= $view->config;
isa_ok $conf, 'HASH';
ok $view->param( page_title => 'TEST PAGE' );
ok $view->param( test_title => 'VIEW TEST' );
ok $body= $view->output('index.tt');
isa_ok $body, 'SCALAR';
like $$body, qr{<html>.+?</html>}s;
like $$body, qr{<title>TEST PAGE</title>}s;
like $$body, qr{<h1>VIEW TEST</h1>}s;
like $$body, qr{<div>TEST OK</div>}s;
like $$body, qr{<p>80</p>}s;

__DATA__
filename: root/index.tt
value: |
 <html>
 <head><title><TMPL_VAR NAME="page_title"></title>
 <body>
 <h1><TMPL_VAR NAME="test_title"></h1>
 <div>TEST OK</div>
 <p><TMPL_VAR NAME="server_port"></p>
 </body>
 </html>
