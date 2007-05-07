
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

#$SIG{__WARN__}= sub {};

my $test= Egg::Helper::VirtualTest->new( prepare=> 1 );

$test->disable_stderr;

SKIP: {
skip q{ WWW::Mechanize::CGI is not installed. } unless $test->mech_ok;

my($mech, $e);
eval{ ($mech, $e)= $test->mech_get('/accept?p1=test1&p2=test2') };
skip q{ VirtualTest->mechanize method is invalid. } if $@;

ok my $req= $e->request;
isa_ok $req,    'Egg::Request::CGI';
isa_ok $req->r, 'Egg::Request::CGI::handler';

can_ok $req, qw{
  e r path snip is_get is_post is_head
  http_user_agent server_protocol remote_user server_name
  script_name request_uri path_info http_referer http_accept_encoding
  remote_addr request_method server_port
  agent user_agent protocol user method port addr address
  referer accept_encoding mp_version uri url
  parameters params param cookie cookies cookie_value secure scheme
  host host_name remote_host args response
  };

is $req->path,      '/accept';
is $req->path_info, '/accept';
ok $req->is_get;
ok ! $req->is_post;
ok ! $req->is_head;
is $req->port, 80;
ok $req->args;
is $req->args, 'p1=test1&p2=test2';

ok my $param= $req->params;
is $param->{p1}, 'test1';
is $param->{p2}, 'test2';

# POST request;
($mech, $e)= $test->mech_post('/accept', { p1=> 'post1', p2=> 'post2' });
ok $req= $e->request;
ok $req->is_post;
ok ! $req->is_get;
ok ! $req->is_head;
ok $param= $req->params;
is $param->{p1}, 'post1';
is $param->{p2}, 'post2';

ok $param->{test}= 1;
is $req->param('test'), 1;
is $req->param('test2'), undef;

  };


