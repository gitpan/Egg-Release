
use Test::More tests=> 4;
use UNIVERSAL::require;
use Egg::Helper;

DBI->require;
plan skip_all => "DBI is not installed." if $@;

my %config= (
  MODEL=> [
    [ 'DBI'=> {
        dsn=> 'dbi:DBD:dbname=dbname',
        user=> 'dbuser',
        },
      ],
    ],
  );

my $t= Egg::Helper->run('O:Test');
$t->prepare({ config=> \%config });

ok( my $e= $t->egg_virtual );
ok( $e->is_model('DBI') );
ok( my $model= $e->model('DBI') );
isa_ok $model, 'Egg::Model::DBI';
