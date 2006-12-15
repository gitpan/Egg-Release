
use Test::More tests=> 3;
use lib 't';
use Egg::Helper::Test;
use EggTest;
my $et= new Egg::Helper::Test;
my $e = new EggTest;

#0
ok( $e->is_model('DBI') );
ok( my $model= $e->model('DBI') );
ok( ref($model) eq 'Egg::Model::DBI' );
