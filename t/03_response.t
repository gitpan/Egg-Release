
use Test::More tests=> 19; # qw/no_plan/
use Egg::Helper;
my $t= Egg::Helper->run('O:Test');
$t->prepare;

my $text= 'Hello world';

ok( my $e= $t->egg_virtual );
ok( my $res= $e->response );
ok( ! $res->status );
ok( $e->finished(200) );
is $res->status, 200;
ok( $e->finished(403) );
is $res->status, 403;
ok( $e->finished(404) );
is $res->status, 404;
ok( $e->finished(500) );
is $res->status, 500;
ok( ! $e->finished(0) );
ok( ! $res->status );
ok( $res->body( $text ) );
isa_ok $res->body, 'SCALAR';
is ${$res->body}, $text;
ok( $res->body( \$text ) );
isa_ok $res->body, 'SCALAR';
is ${$res->body}, $text;
