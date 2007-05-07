
use Test::More tests => 82;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new( prepare=> 1 );
my $project_name= $test->project_name;
my $text= 'Hello world';
my $e= $test->egg_pcomp_context;

ok my $res= $e->response;
isa_ok $res, 'Egg::Response';

can_ok $res, qw{
  e request content_type content_language location no_cache last_modified
  _startup new cookie cookies body headers header attachment window_target
  content_encoding status status_string redirect clear_body clear_cookies
  clear result is_expires
  };

ok ! $res->status;
ok $e->finished(200);
is $res->status, 200;
is $res->status_string, ' OK';
ok $e->finished(403);
is $res->status, 403;
is $res->status_string, ' Forbidden';
ok $e->finished(404);
is $res->status, 404;
is $res->status_string, ' Not Found';
ok $e->finished(500);
is $res->status, 500;
is $res->status_string, ' Internal Server Error';
ok ! $e->finished(0);
ok ! $res->status;
is $res->status_string, ' OK';

ok ! $res->body;
ok $res->body('test');
ok my $body= $res->body;
isa_ok $body, 'SCALAR';
is $$body, 'test';
ok $res->body($text);
ok $$body, ${$res->body};
ok $body= $res->body;
is $$body, $text;

ok $res->headers;
isa_ok $res->headers, 'HTTP::Headers';

ok my $cookies= $res->cookies;
isa_ok $cookies, 'HASH';
isa_ok tied(%$cookies), 'Egg::Response::TieCookie';
ok $cookies->{test}= 'foo';
ok $cookies->{test};
isa_ok $cookies->{test}, 'Egg::Response::FetchCookie';
ok $cookies->{test}->name;
is $cookies->{test}->name,  $cookies->{test}->{name};
ok $cookies->{test}->value;
is $cookies->{test}->value, $cookies->{test}->{value};
ok $res->cookie( test2=> 'hoge' );
ok $cookies->{test2};
isa_ok $res->cookie('test2'), 'Egg::Response::FetchCookie';
is $res->cookie('test2')->value, $cookies->{test2}->{value};

ok ! $res->content_type;
ok ! $res->content_language;
ok $res->content_language('ja');
ok $res->attachment('test.file');
ok $res->window_target('test');
ok $res->content_encoding('identity');
ok my $header= $res->header($body);
like $$header, qr{\bContent\-Type\: +text/html}s;
like $$header, qr{\bContent\-Language\: +ja}s;
like $$header, qr{\bWindow\-Target\: +test}s;
like $$header, qr{\bContent\-Disposition\: +attachment\; +filename\=test\.file};
like $$header, qr{\bContent\-Encoding\: +identity}s;
like $$header, qr{\bSet\-Cookie\: +test=foo\; +.+}s;
like $$header, qr{\bSet\-Cookie\: +test2=hoge\; +.+}s;
like $$header, qr{\bX\-Egg\-$project_name\: +\d+\.\d+}s;
ok $res->clear;
ok ! $$header;
ok ! $cookies->{test};
ok ! $cookies->{test2};
ok ! $res->content_type;
ok ! $res->content_language;
ok ! $res->attachment;
ok ! $res->window_target;
ok ! $res->content_encoding;

ok $$body;
ok ! $res->clear_body;
ok ! $$body;

ok $res->redirect('/redirect');
ok $res->status;
is $res->status, 302;
ok $res->status_string;
is $res->status_string, ' Moved Temporarily';
ok $res->location;
is $res->location, '/redirect';

ok $header= $res->header($body);
ok $$header;

like $$header, qr{\bStatus\: +302 Moved Temporarily}s;
like $$header, qr{\bLocation\: +/redirect}s;

