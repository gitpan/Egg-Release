
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $dsn   = $ENV{EGG_RDBMS_DSN}        || "";
my $uid   = $ENV{EGG_RDBMS_USER}       || "";
my $psw   = $ENV{EGG_RDBMS_PASSWORD}   || "";
my $table = $ENV{EGG_RDBMS_TEST_TABLE} || 'egg_release_dbi_test_table';

SKIP: {
skip q{ Data base is not setup. } unless ($dsn and $uid);

eval{ require DBI };
skip q{ 'DBI' module is not installed. } if $@;

my $test= Egg::Helper::VirtualTest->new;
$test->prepare( config => {
  MODEL=> [[ DBI=> {
    dsn      => $dsn,
    user     => $uid,
    password => $psw,
    option   => { RaiseError=> 1 },
    }]] } );

my $e= $test->egg_pcomp_context;

ok my $dbi= $e->model('DBI');
isa_ok $dbi, 'Egg::Model::DBI';
can_ok $dbi, qw/ dbh /;

my $dbh;
eval{ $dbh= $dbi->dbh };
skip q{ Doesn't connect with the data base. } if ($@ or ! $dbh);

my $ima= $dbi->isa('Ima::DBI') ? 1: 0;

$ima ? do { isa_ok $dbh, 'DBIx::ContextualFetch::db' }
     : do { isa_ok $dbh, 'DBI::db' };

eval{
$dbh->do(<<"END_ST");
CREATE TABLE $table (
  id     int2      primary key,
  test   varchar
  );
END_ST
  };

skip q{ No permission to create table. } if $@;

my $result;

ok my $sth= $dbh->prepare(qq{ INSERT INTO $table (id, test) VALUES (?, ?) });
for my $db ([1, 'foo1'], [2, 'foo2'], [3, 'foo3']) {
	ok $sth->execute(@$db);
}
ok my $count= $dbh->prepare(qq{ SELECT count(id) FROM $table });
ok $count->execute;
ok $count->bind_columns(\$result);
ok $count->fetch;
ok $result;
is $result, 3;

ok $sth= $dbh->prepare(qq{ SELECT test FROM $table WHERE id = ? });
ok $sth->execute('2');
ok $sth->bind_columns(\$result);
ok $sth->fetch;
ok $result;
is $result, 'foo2';

ok $dbh->do(qq{ DELETE FROM $table });

ok $count->execute;
ok $count->bind_columns(\$result);
ok $count->fetch;
ok ! $result;

ok $dbh->do(qq{ DROP TABLE $table });

  };

