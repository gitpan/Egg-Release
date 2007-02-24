
use Test::More qw/no_plan/;
use Egg::Helper;

$ENV{REMOTE_ADDR} = '127.0.0.1';
$ENV{HTTP_REFERER}= 'http://localdomain/test.test';
$ENV{HTTP_COOKIE} = 'build=test;';

my $uri= 'https://domain.name/test?test1=1&test2=2';

ok( my $t= Egg::Helper->run('O:Test') );
ok( $t->create_project_root );
ok( $t->prepare );
ok( $egg= $t->attach_request('GET', $uri) );
ok( my $project_name= $t->project_name );
is $egg->namespace, $project_name;
isa_ok $egg, $project_name;
ok( $egg->isa('Egg') );
is $egg->request->param, 2;
ok( my $params= $egg->request->params );

ok( $params->{test1} );
is $params->{test1}, 1;
ok( $params->{test2} );
is $params->{test2}, 2;
ok( $params->{test3}= 3 );
is $egg->request->param, 3;
is $egg->request->param('test3'), 3;
is $egg->is_request, 'Egg::Request::CGI';
ok( my $req= $egg->request );
isa_ok $req, 'Egg::Request::CGI';

is $req->uri, $uri;
is $req->host, 'domain.name';
is $req->host_name, 'domain.name';
is $req->server_name, 'domain.name';
is $req->script_name, '/test';
ok( $req->secure );
is $req->scheme, 'https';
is $req->path,   '/test';
is $req->args,   'test1=1&test2=2';
is $req->port,   443;

is $req->agent,   $project_name;
is $req->address, '127.0.0.1';
ok( $req->cookies );
isa_ok $req->cookies, 'HASH';
ok( my $cookie= $req->cookie('build') );
is $cookie->value, 'test';
is $egg->is_response, 'Egg::Response';
ok( my $res= $egg->response );
isa_ok $res, 'Egg::Response';
ok( my $cookies= $res->cookies );

isa_ok $cookies, 'HASH';
isa_ok tied(%$cookies), 'Egg::Response::TieCookie';
is $egg->is_engine, 'Egg::Engine::V1';
ok( $egg->isa('Egg::Engine::V1') );
is $egg->is_dispatch, 'Egg::Dispatch::Runmode';
ok( my $dis= $egg->dispatch );
isa_ok $dis, "$project_name\::D";
ok( $dis->isa('Egg::Dispatch::Runmode') );
ok( my $run= $dis->run_modes );
isa_ok $run, 'HASH';

ok( $run->{_default} );
isa_ok $run->{_default}, 'CODE';
ok( ! $egg->model );
ok( $egg->is_view('Template') );
is $egg->default_view, 'Template';
ok( my $view= $egg->view );
isa_ok $view, 'Egg::View::Template';

ok( $egg->config->{view}{Template} );
is $egg->config->{root}, $t->project_root;
ok( my $catch= $t->response_catch($egg, 'handler') );
ok( $CRLF= $Egg::CRLF );
like $$catch, qr/\bX\-Egg\-$project_name\:\s+[\d\.]+$CRLF/s;
like $$catch, qr/\bContent\-Type\:\s+text\/html$CRLF/s;
like $$catch, qr/<html.*?>.+?<\/html>/s;
like $$catch, qr/<body>.+?<\/body>/s;
like $$catch, qr/<title>$project_name\-[\d\.]+<\/title>/s;
like $$catch, qr/<h1>.+?BLANK\s+PAGE.+?<\/h1>/;
