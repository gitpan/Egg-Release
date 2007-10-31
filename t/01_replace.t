
package ReplaceTest;
use strict;

use Test::More tests => 12;
use base qw/Egg::Base/;

my $test= __PACKAGE__->SUPER::new;

my %param= (   
  foo => 'test',
  hoo => { a => '< $e.foo >', b => '< $e.foo >' },
  boo => ['<$e.hoo.a>', '<$e.hoo.b>', { ok => '<$e.foo>' }],
  zoo => { z1=> '< $e.hoo >', z2 => { ok => '< $e.hoo.a >' } },
  bad => '\< $e.foo >',
  );

$test->replace_deep(\%param, $param{hoo});
$test->replace_deep(\%param, $param{boo});
$test->replace_deep(\%param, \%param);

ok %param;
is $param{hoo}{a}, 'test';
is $param{hoo}{b}, 'test';
is $param{boo}[0], 'test';
is $param{boo}[1], 'test';
isa_ok $param{boo}[2], 'HASH';
is $param{boo}[2]{ok}, 'test';
isnt ref($param{zoo}{z1}), 'HASH';
like $param{zoo}{z1}, qr{^HASH\(0x[a-f0-9]+\)};
isa_ok $param{zoo}{z2}, 'HASH';
is   $param{zoo}{z2}{ok}, 'test';
like $param{bad}, qr{^<\$?e\.foo>$};

