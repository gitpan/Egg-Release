
use Test::More tests=> 7;
use lib 't';

#0
use_ok('EggTest');
use_ok('Egg::Helper::Test');
ok( my $et= new Egg::Helper::Test );
ok( my $e = new EggTest );
ok( ref($e) eq $et->testname );

#5
ok( $e->isa('Egg') );
ok( $e->isa('Egg::Engine') );
