
use Test::More tests => 9;
use lib 't';
use EggTest;
my $e= new EggTest;

#0
ok( my $res= $e->response );
$e->finished(200);
ok( $res->status== 200 );
$e->finished(403);
ok( $res->status== 403 );
$e->finished(404);
ok( $res->status== 404 );
$e->finished(500);
ok( $res->status== 500 );
$e->finished(200);

#5
my $text= 'Hello world';
$res->body( $text );
ok( ref($res->body) eq 'SCALAR' );
ok( ${$res->body} eq $text );
$res->body( \$text );
ok( ref($res->body) eq 'SCALAR' );
ok( ${$res->body} eq $text );
