
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new;

$test->disable_stderr;

isa_ok $test, 'Egg::Helper::VirtualTest';
ok my $g= $test->global;
isa_ok $g, 'HASH';
is $test->project_name, $g->{project_name};
is $test->project_root, $g->{project_root};
ok my $pname= $test->project_name;
   my $lc_pname= lc($pname);
ok my $proot= $test->project_root;
ok -e $test->project_root and -d _;
ok $test->prepare;
ok -e "$proot/lib/$pname.pm"             and -f _;
ok -e "$proot/lib/$pname/config.pm"      and -f _;
ok -e "$proot/bin/trigger.cgi"           and -f _;
ok -e "$proot/bin/${lc_pname}_helper.pl" and -f _;

ok my $e= $test->egg_context;
isa_ok $e, $pname;
ok $e->request;
isa_ok $e->request,   'Egg::Request::CGI';
ok $e->response;
isa_ok $e->response,  'Egg::Response';
ok $e->debugging;
isa_ok $e->debugging, 'Egg::Plugin::Debugging::handler';
ok $e->dispatch;
isa_ok $e->dispatch,  'Egg::Plugin::Dispatch::Standard::handler';
ok $e->log;
isa_ok $e->log,       'Egg::Plugin::Log::handler';
ok $e->view;
isa_ok $e->view,      'Egg::View::Template';

ok $e= $test->egg_pcomp_context;
isa_ok $e, $pname;

SKIP: {
skip q{ WWW::Mechanize::CGI is not installed. } unless $test->mech_ok;

my $mech;
eval{ $mech= $test->mech_get('/') };
skip q{ VirtualTest->mechanize method is invalid. } if $@;

ok $mech->content;
like $mech->content, qr{<html.*?>.+?</html>}s;
like $mech->content, qr{<title.*?>.+?</title>}s;
like $mech->content, qr{<h1.*?>.+?</h1>}s;

  };
