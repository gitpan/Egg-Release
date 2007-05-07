
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

SKIP: {

eval{ require HTML::Mason };
skip q{ HTML::Mason is not installed. } if $@;

my $test= Egg::Helper::VirtualTest->new;
   $test->prepare(
     config=> { VIEW=> [ [
       Mason => {
         comp_root => [
           [ main    => '< $e.dir.template >' ],
           [ private => '< $e.dir.comp >' ],
           ],
         data_dir => '< $e.dir.tmp >',
         },
       ] ] },
     create_files => $test->yaml_load( join '', <DATA> ),
     );

my $e= $test->egg_pcomp_context;

ok my $view= $e->view('Mason');
isa_ok $view, 'Egg::View::Mason';
can_ok $view, qw/ new output render _setup /;
ok my $conf= $view->config;
isa_ok $conf, 'HASH';
ok $e->page_title('TEST PAGE');
ok $e->stash( test_title => 'VIEW TEST' );
ok $view->param( server_port => $e->request->port );
ok $body= $view->output('index.tt');
isa_ok $body, 'SCALAR';
like $$body, qr{<html>.+?</html>}s;
like $$body, qr{<title>TEST PAGE</title>}s;
like $$body, qr{<h1>VIEW TEST</h1>}s;
like $$body, qr{<div>TEST OK</div>}s;
like $$body, qr{<p>80</p>}s;

  };

__DATA__
---
filename: root/index.tt
value: |
 <html>
 <head><title><% $e->page_title %></title></head>
 <body>
 <h1><% $s->{test_title} %></h1>
 <div>TEST OK</div>
 <p><% $p->{server_port} %></p>
 </body>
 </html>
