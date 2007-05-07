
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new( prepare=> {
  controller => { egg_includes=> [qw/Encode/] },
  config     => { character_in=> 'utf8' },
  });

$test->disable_stderr;

SKIP: {
eval{ require Jcode };
skip q{ Jcode module is not installed. } if $@;

my($mech, $e)= @_;
eval{ ($mech, $e)= $test->mech_post('/', { test=> 'テスト表示' }) };
skip q{ VirtualTest->mech_post method is invalid. } if $@;

can_ok $e, qw/ create_encode euc_conv sjis_conv utf8_conv /;

ok my $param= $e->request->params;
ok $param->{test};
ok my @code= Jcode::getcode($param->{test});
ok $code[0], 'utf8';

  };
