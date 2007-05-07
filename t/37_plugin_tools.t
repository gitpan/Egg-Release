
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new( prepare=> {
  controller=> { egg_includes=> [qw/ Tools /] },
  });

ok my $e= $test->egg_context;
can_ok $e, qw/
  escape_html
  eHTML
  unescape_html
  ueHTML
  escape_uri
  eURI
  unescape_uri
  ueURI
  encode_entities
  decode_entities
  encode_entities_numeric
  uri_escape
  uri_escape_utf8
  uri_unescape
  md5_hex
  comma
  shuffle_array
  /;

my $text= 'ABCDEFGHIJK0123456789';

ok my $hex= $e->md5_hex($text);
is $hex, $e->md5_hex(\$text);

my $num= '-12345.123';
ok my $cnum= $e->comma($num);
is $cnum, '-12,345.123';

my @array1= @array2= (0..100);
ok $e->shuffle_array(\@array1);
my $ne;
for (0..9) { $array1[$_] ne $array2[$_] and do { ++$ne; last } }
ok $ne;

