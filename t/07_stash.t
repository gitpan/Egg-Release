
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new( prepare=> 1 );
my $e   = $test->egg_context;

ok $e->stash;
isa_ok $e->stash, 'HASH';
ok $e->stash->{param1}= 'test1';
ok $e->stash( 'param2'=> 'test2' );
is $e->stash->{param1}, 'test1';
is $e->stash('param1'), 'test1';
is $e->stash->{param2}, 'test2';
is $e->stash('param2'), 'test2';
ok my $stash= $e->stash;
is $stash->{param1}, 'test1';
is $stash->{param2}, 'test2';
is $stash->{param1}, $e->stash('param1');
is $stash->{param2}, $e->stash('param2');

