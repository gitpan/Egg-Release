
use Test::More tests => 7;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new
    ( prepare=> { controller => { egg_includes=> [qw/YAML/] } });

ok my $e= $test->egg_context;
ok my $yaml= $e->yaml_load( join '', <DATA> );
isa_ok $yaml, 'HASH';
ok $yaml->{test1};
is $yaml->{test1}, 'foo1';
ok $yaml->{test2};
is $yaml->{test2}, 'foo2';

__DATA__
test1: foo1
test2: foo2
