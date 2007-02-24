
use Test::More tests => 8;
use Egg::Helper;
eval{ use Jcode };
plan skip_all => "Jcode required for testing plugin." if $@;

my $t= Egg::Helper->run('O:Test');

$t->prepare( controller=> { egg=> [qw/Encode/] } );

ok(
  my $e= $t->attach_request
    ('GET', 'http://domain.name/?test1=a1&test2=a2')
  );
ok( my $param= $e->request->params );
ok( $param->{test1} );
is $param->{test1}, 'a1';
ok( $param->{test2} );
is $param->{test2}, 'a2';
ok( $e->encode );
isa_ok $e->encode, 'Jcode';

