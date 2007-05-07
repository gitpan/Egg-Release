
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

SKIP: {
eval{ require Jcode };
skip q{ Jcode module is not installed. } if $@;

my $test= Egg::Helper::VirtualTest->new;

$test->disable_stderr;

$test->prepare(
  controller=> {
    egg_includes => [qw/ Charset::UTF8 /],
    dispatch     => '_default=> sub {}',
    },
  create_files=> [ $test->yaml_load( join '', <DATA> ) ],
  );

my $mech;
eval{ $mech= $test->mech_get('/') };
skip q{ VirtualTest->mech_get method is invalid. } if $@;

ok my $body= $mech->content;
ok my @code= Jcode::getcode( $body );
ok $code[0], 'utf8';

  };

__DATA__
filename: root/index.tt
value: |
  <test>テスト表示</test>
