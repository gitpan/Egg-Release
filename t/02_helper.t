
use Test::More qw/no_plan/;
use Egg::Helper;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new;

my $startdir= $test->start_dir;
my $proot   = $test->project_root;

$test->disable_allstd;

$ENV{EGG_DEBUG}        = 1;
$ENV{EGG_MAKEMAKER}    = 0;
$ENV{EGG_OUT_PATH}     = $proot;
$ENV{EGG_INC}          = "$startdir/lib $startdir/../lib";
$ENV{EGG_PROJECT_NAME} = 'TestProject';

Egg::Helper->run('Project');
ok $test->chdir("$proot/TestProject");

eval {

	ok -e './lib/TestProject.pm';
	ok -e './lib/TestProject/config.pm';
	ok -e './bin/trigger.cgi';
	ok -e './bin/dispatch.fcgi';
	ok -e './bin/testproject_helper.pl';
	ok -e './bin/testproject_tester.pl';

	push @INC, "$proot/TestProject/lib";
	require TestProject;

	ok my $e= TestProject->new;
	isa_ok $e, 'TestProject';
	can_ok 'TestProject', '_start_engine';

	ok $e->can('handler');
	ok $e->_prepare_model;
	ok $e->_prepare_view;

	## Request.
	ok my $req= $e->request;
	isa_ok $req, ref($e->req);
	ok $req->response;
	isa_ok $req->response, 'Egg::Response';
	ok $req->is_get;
	ok ! $req->is_post;
	ok ! $req->is_head;
	is $req->port, 80;
	ok ! $req->secure;
	is $req->scheme, 'http';
	like $req->address, qr{^\d+\.\d+\.\d+\.\d+$};
	like $req->uri, qr{^http\://localhost/};
	like $req->host, qr{^localhost$};
	like $req->host_name, qr{^localhost$};
	isa_ok $req->snip, 'ARRAY';
	ok ! join('', @{$req->snip});
	ok $req->path;
	is $req->path, '/';

	## Response.
	ok my $res= $e->response;
	isa_ok $res, ref($e->res);
	ok $res->request;
	isa_ok $res->request, 'Egg::Request';
	isa_ok $res->headers, 'Egg::Response::Headers';
	is $res->status, 0;

	## model.
	ok ! $e->model;

	## view.
	ok $e->view;
	isa_ok $e->view, 'Egg::View::Template';

	## prepare.
	ok $e->_prepare;
	isa_ok $e->_prepare, ref($e);

	## dispatch.
	isa_ok $e->dispatch, 'Egg::Plugin::Dispatch::Standard::handler';
	ok $e->_dispatch_start;
	ok $e->_dispatch_action;
	ok $e->_dispatch_finish;
	ok ! $res->content_type;
	ok ! $e->finished;
	ok $res->body;
	isa_ok $res->body, 'SCALAR';
	ok ${$res->body};

	## finalize.
	ok $e->_finalize;
	isa_ok $e->_finalize, ref($e);

	## finalize_output.
	ok $e->_finalize_output;
	is $res->status, 200;
	ok my $content_type= $res->content_type;
	like $content_type, qr{^text/html};
	ok $e->finished;

	## output content.
	ok my $body= $res->body;
	like $res->{header}, qr{\bContent\-Type\:\s$content_type}s;
	unlike $res->{header}, qr{\bX\-Egg\-TestProject\-ERROR}is;
	like $$body, qr{<html.*?>.+?</html>}s;
	like $$body, qr{<title>.+?</title>}s;
	like $$body, qr{<h1>.+?</h1>}s;
  };

$@ and die $@;
$test->chdir($startdir);
