
use Test::More tests => 14;
use lib 't';
use EggTest;
my $e= new EggTest;
my $res= $e->response;

my $header;

#0
ok( $res->no_cache(1) );
$header= $res->create_header;
like( $$header, qr{Expires\:\s+0}s );
like( $$header, qr{Pragma\:\s+no\-cache}s );
like( $$header, qr{Cache\-Control\:\s+no\-cache}s );
like( $$header, qr{Last\-Modified:\s+.+}s );

#5
ok( ! $res->no_cache(0) );
$header= $res->create_header;
ok( $$header=~m{Expires\:\s+0}s ? 0: 1 );
ok( $$header=~m{Pragma\:\s+no\-cache}s ? 0: 1 );
ok( $$header=~m{Cache\-Control\:\s+no\-cache}s ? 0: 1 );
ok( $$header=~m{Last\-Modified:\s+.+}s ? 0: 1 );

#10
ok( $res->ok_cache(1) );
$header= $res->create_header;
like( $$header, qr{Last\-Modified:\s+.+}s );

ok( ! $res->ok_cache(0) );
$header= $res->create_header;
ok( $$header=~m{Last\-Modified:\s+.+}s ? 0: 1 );
