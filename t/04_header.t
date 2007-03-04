
use Test::More tests=> 20;
use Egg::Helper;
my $t= Egg::Helper->run('O:Test');
$t->prepare;

my $e   = $t->egg_virtual;
my $res = $e->response;
my $CRLF= $Egg::CRLF;

ok( $res->headers );
ok( ref($res->headers) eq 'HTTP::Headers' );
ok( $res->content_type('image/jpeg') );
ok( my $header= $res->create_header($res->body) );
like( $$header, qr{Content-Type\:\s+image/jpeg}is );
ok( $$header!~/Content-Language\:\s+[\n]+?/s );
ok( $res->content_type("text/html") );
ok( ! $res->content_encoding('deflate') );
ok( ! $res->header( 'X-Test'=> 1 ) );
ok( $res->push_header( 'X-Test'=> 2 ) );
ok( ! $res->headers->header( 'X-Foo'=> 3 ) );
ok( $res->headers->push_header( 'X-Foo'=> 4 ) );
ok( $header= $res->create_header($res->body) );
like $$header, qr{\bContent\-Language\:\s+ja$CRLF}is;
like $$header, qr{\bContent\-Type\:\s+text/html$CRLF}is;
like $$header, qr{\bContent\-Encoding\:\s+deflate$CRLF}is;
like $$header, qr{\bX\-Test\:\s+1$CRLF}is;
like $$header, qr{\bX\-Test\:\s+2$CRLF}is;
like $$header, qr{\bX\-Foo\:\s+3$CRLF}is;
like $$header, qr{\bX\-Foo\:\s+4$CRLF}is;
