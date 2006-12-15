package EGG_TEST;
use strict;
use Test::More tests=> 8;
use lib 't';

eval { use Egg::Plugin::YAML };

plan skip_all=> "Egg::Plugin::YAML required." if $@;

use Egg qw/YAML/;
$ENV{EGG_TEST_UNLOAD_DISPATCHER}= 'EGG_TEST::D';

__PACKAGE__->__egg_setup( {} );
my $e= __PACKAGE__->new;

my $yaml= <<END_OF_YAML;
t_param1: test1
t_array:
  - test2
  - test3
t_hash:
  1: test4
  2: test5
END_OF_YAML

#0
ok( my $hash= $e->yaml_load($yaml) );
like $hash->{t_param1}, qr/^test1$/;
ok( ref($hash->{t_array}) eq 'ARRAY' );
like $hash->{t_array}[0], qr/^test2$/;
like $hash->{t_array}[1], qr/^test3$/;

#5
ok( ref($hash->{t_hash}) eq 'HASH' );
like $hash->{t_hash}{1}, qr/^test4$/;
like $hash->{t_hash}{2}, qr/^test5$/;

package EGG_TEST::D;
use strict;
sub _setup {}

1;
