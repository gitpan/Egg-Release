
use Test::More tests=> 9;
use lib 't';
use EggTest;
my $e= new EggTest;

#0
ok( $e->stash->{param1}= 'test1' );
ok( $e->stash( 'param2'=> 'test2' ) );
like $e->stash->{param1}, qr/^test1$/;
like $e->stash( 'param1' ), qr/^test1$/;
like $e->stash->{param2}, qr/^test2$/;

#5
like $e->stash( 'param2' ), qr/^test2$/;
ok( my $stash= $e->stash );
like $stash->{param1}, qr/^test1$/;
like $stash->{param2}, qr/^test2$/;

