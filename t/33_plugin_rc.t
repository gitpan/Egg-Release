
use Test::More tests => 8;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new;
$test->prepare(
  controller   => { egg_includes=> [qw/ rc /] },
  create_files => [$test->yaml_load( join '', <DATA> )],
  );

ok my $e = $test->egg_context;
can_ok $e, qw/ load_rc /;
ok my $rc= $e->load_rc;
isa_ok $rc, 'HASH';
ok $rc->{test1};
is $rc->{test1}, 'OK1';
ok $rc->{test2};
is $rc->{test2}, 'OK2';

__DATA__
filename: .egg_releaserc
value: |
  test1: OK1
  test2: OK2
