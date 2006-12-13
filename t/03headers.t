
use Test::More tests => 12;
use lib 't';
use EggTest;
my $e= new EggTest;
my $res= $e->response;

my $header;

#0
ok( $res->content_type("image/jpeg") );
ok( $header= $res->create_header($res->body) );
like( $$header, qr{Content-Type\:\s+image/jpeg}is );

$res->content_language('ja');
ok( $res->content_type("text/html") );
$res->content_encoding('deflate');
$res->header( 'X-Test'=> 1 );
$res->push_header( 'X-Test'=> 2 );
$res->headers->header( 'X-Foo'=> 3 );
$res->headers->push_header( 'X-Foo'=> 4 );
ok( $header= $res->create_header($res->body) );

#5
like( $$header, qr{Content\-Language\:\s+ja}is );
like( $$header, qr{Content\-Type\:\s+text/html}is );
like( $$header, qr{Content\-Encoding\:\s+deflate}is );
like( $$header, qr{X\-Test\:\s+1}is );
like( $$header, qr{X\-Test\:\s+2}is );

#10
like( $$header, qr{X\-Foo\:\s+3}is );
like( $$header, qr{X\-Foo\:\s+4}is );
