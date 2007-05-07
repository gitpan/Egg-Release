
use Test::More tests => 23;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new( prepare=> {
  controller=> { egg_includes=> [qw/ HTTP::HeadParser /] },
  });

my @example= split /\n+\---\n+/, join('', <DATA>);
ok my $e= $test->egg_context;
can_ok $e, qw/ parse_http_header /;

# request header.
ok my $request= $e->parse_http_header( $example[0] );
isa_ok $request, 'HASH';
is $request->{method},          'GET / HTTP/1.1';
is $request->{accept},          'image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, */*';
is $request->{referer},         'http://domain.name/';
is $request->{accept_language}, 'en-us';
is $request->{accept_encoding}, 'gzip, deflate';
is $request->{user_agent},      'Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET)';
is $request->{host},            'domain.name';
is $request->{connection},      'Keep-Alive';
is $request->{cookie},          'test=OK;';

# response header.
ok my $response= $e->parse_http_header( $example[1] );
isa_ok $response, 'HASH';
is $response->{status},         'HTTP/1.1 200 OK';
is $response->{connection},     'close';
is $response->{server},         'Apache';
is $response->{cache_control},  'private, max-age=0';
is $response->{content_type},   'text/xml; charset=utf-8';

ok ! $response->{content1};
ok ! $response->{content2};
ok ! $response->{content3};

__DATA__
GET / HTTP/1.1
Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, application/x-shockwave-flash, */*
Referer: http://domain.name/
Accept-Language: en-us
Accept-Encoding: gzip, deflate
User-Agent: Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; .NET)
Host: domain.name
Connection: Keep-Alive
Cookie: test=OK;
---
HTTP/1.1 200 OK
Connection: close
Server: Apache
Cache-Control: private, max-age=0
Content-Type: text/xml; charset=utf-8

content1
content2
content3
