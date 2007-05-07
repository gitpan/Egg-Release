
use Test::More qw/no_plan/;

use Egg::Helper::VirtualTest;
my $test= Egg::Helper::VirtualTest->new( prepare=> 1 );
my $e   = $test->egg_pcomp_context;
my $res = $e->response;

ok $res->no_cache(1);
ok $header= $res->header;

like $$header, qr{\bExpires\: +.+? +GMT}s;
like $$header, qr{\bPragma\: +no\-cache}s;
like $$header, qr{\bCache\-Control\: +no\-cache\,.+}s;
like $$header, qr{\bLast\-Modified\: +.+? +GMT}s;
