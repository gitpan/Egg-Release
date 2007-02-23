
use Test::More tests => 18;
use Egg::Helper;
my $t= Egg::Helper->run('O:Test');
$t->prepare;
my $e   = $t->egg_virtual;
my $res = $e->response;
my $CRLF= $Egg::CRLF;

ok( $res->no_cache(1) );
ok( my $header= $res->create_header );
like $$header, qr{\bExpires\:\s+0$CRLF}s;
like $$header, qr{\bPragma\:\s+no\-cache$CRLF}s;
like $$header, qr{\bCache\-Control\:\s+no\-cache\,\s+no\-store\,\s+must\-revalidate$CRLF}s;
like $$header, qr{\bLast\-Modified\:\s+.+?$CRLF}s;

ok( ! $res->no_cache(0) );
ok( $header= $res->create_header );
ok( ! $$header=~m{\bExpires\:\s+0$CRLF}s ? 0: 1 );
ok( ! $$header=~m{\bPragma\:\s+no\-cache$CRLF}s ? 0: 1 );
ok( ! $$header=~m{\bCache\-Control\:\s+no\-cache\,\s+no\-store\,\s+must\-revalidate$CRLF}s ? 0: 1 );
ok( ! $$header=~m{\bLast\-Modified\:\s+.+?$CRLF}s ? 0: 1 );

ok( $res->ok_cache(1) );
ok( $header= $res->create_header );
like $$header, qr{\bLast\-Modified:\s+.+?$CRLF}s;

ok( ! $res->ok_cache(0) );
ok( $header= $res->create_header );
ok( $$header=~m{\bLast\-Modified:\s+.+?$CRLF}s ? 0: 1 );
