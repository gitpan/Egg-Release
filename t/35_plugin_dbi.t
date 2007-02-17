
use Test::More tests => 9;
use Egg::Helper;
eval{ use DBI };
plan skip_all => "DBI required for testing plugin." if $@;

my $t= Egg::Helper->run('O:Test');

$t->prepare(
  controller=> { egg=> [qw/DBI::Accessors::Extra/] },
  config=> {
    MODEL=> [['DBI'=> {
      dsn => 'dbi:DBD:dbname=database',
      user=> 'dbuser',
      }]],
    },
  );

ok( my $e= $t->egg_virtual );
ok( $e->can('dbh') );
ok( $e->can('commit_ok') );
ok( $e->can('rollback_ok') );
ok( $e->can('dbh_hashref') );
ok( $e->can('dbh_scalarref') );
ok( $e->can('dbh_arrayref') );
ok( $e->can('dbh_any') );
ok( $e->can('db') );

