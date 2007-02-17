
use Test::More tests=> 11;
use Egg::Helper;
my $t= Egg::Helper->run('O:Test');
$t->prepare;
my $e= $t->egg_virtual;

ok( $e->stash );
isa_ok $e->stash, 'HASH';
ok( $e->stash->{param1}= 'test1' );
ok( $e->stash( 'param2'=> 'test2' ) );
is $e->stash->{param1}, 'test1';
is $e->stash('param1'), 'test1';
is $e->stash->{param2}, 'test2';
is $e->stash('param2'), 'test2';
ok( my $stash= $e->stash );
is $stash->{param1}, 'test1';
is $stash->{param2}, 'test2';

