
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $dsn   = $ENV{EGG_RDBMS_DSN}        || "";
my $uid   = $ENV{EGG_RDBMS_USER}       || "";
my $psw   = $ENV{EGG_RDBMS_PASSWORD}   || "";
my $table = $ENV{EGG_RDBMS_TEST_TABLE} || 'egg_release_dbi_test_table';

SKIP: {
skip q{ Data base is not setup. }, 40 unless ($dsn and $uid);

eval{ require DBI };
skip q{ 'DBI' module is not installed. }, 40 if $@;

eval{ require Time::Piece::MySQL };
skip q{ 'Time::Piece::MySQL' is not installed. }, 40 if $@;

my $test= Egg::Helper::VirtualTest->new( prepare=> {
  controller=> { egg_includes=> [qw/ DBI::Easy /] },
  config    => { MODEL => [
    [ DBI => { dsn => $dsn, user => $uid, password => $psw } ],
    ] },
  });

ok my $e= $test->egg_pcomp_context;
can_ok $e, qw/
  dbh
  dbh_hashref
  dbh_scalarref
  dbh_arrayref
  db
  sql_datetime
  /;
can_ok 'Egg::Plugin::DBI::Easy', qw/
  _prepare
  /;
can_ok 'Egg::Plugin::DBI::Easy::handler', qw/
  new
  AUTOLOAD
  DESTROY
  /;
can_ok 'Egg::Plugin::DBI::Easy::accessors', qw/
  new
  scalarref
  hashref
  arrayref
  insert
  update
  upgrade
  delete
  clear
  /;

my $dbh;
eval{ $dbh= $e->dbh };
skip q{ Doesn't connect with the data base. }, 40 if ($@ or ! $dbh);

eval{
$dbh->do(<<"END_ST");
CREATE TABLE $table (
  id     int2      primary key,
  test   varchar
  );
END_ST
  };

skip q{ No permission to create table. } if $@;

ok my $sth= $dbh->prepare(qq{ INSERT INTO $table (id, test) VALUES (?, ?) });
for my $db ([1, 'foo1'], [2, 'foo2'], [3, 'foo3']) {
	ok $sth->execute(@$db);
}

# dbh_hashref.
ok my $hash= $e->dbh_hashref('id', qq{ SELECT * FROM $table WHERE id = ? }, 1);
is $hash->{id}, 1;
is $hash->{test}, 'foo1';

# dbh_arrayref.
ok my $array= $e->dbh_arrayref(qq{ SELECT * FROM $table ORDER BY id });
is scalar(@$array), 3;
isa_ok $array->[0], 'HASH';
is $array->[0]{id}, 1;
is $array->[0]{test}, 'foo1';

# dbh_scalarref.
ok my $scalar= $e->dbh_scalarref(qq{ SELECT test FROM $table WHERE id = ? }, 2);
isa_ok $scalar, 'SCALAR';
is $$scalar, 'foo2';

# insert.
ok $e->db->$table->insert({ id => 4, test => 'foo4' });

# hashref.
ok $hash= $e->db->$table->hashref(['id', 'test'], 'id = ?', 4);
isa_ok $hash, 'HASH';
is $hash->{id}, 4;
is $hash->{test}, 'foo4';

# arrayref.
ok $array= $e->db->$table->arrayref(0, ['ORDER BY id']);
isa_ok $array, 'ARRAY';
is scalar(@$array), 4;
isa_ok $array->[0], 'HASH';
is $array->[0]{id}, 1;
is $array->[0]{test}, 'foo1';

# scalarref.
ok $scalar= $e->db->$table->scalarref('test', 'id = ?', 4);
isa_ok $scalar, 'SCALAR';
is $$scalar, 'foo4';

# update.
ok $e->db->$table->update('id', { id => 2, test => 'hoge2' });
ok $scalar= $e->db->$table->scalarref('test', 'id = ?', 2);
is $$scalar, 'hoge2';

# upgrade.
ok $e->db->$table->upgrade({ test => 'OK' });
ok $array= $e->db->$table->arrayref;
for (@$array) { is $_->{test}, 'OK' }

# update_insert 1.
ok $e->db->$table->update_insert('id', { id => 4, test => 'update OK' });
ok $scalar= $e->db->$table->scalarref('test', 'id = ?', 4);
is $$scalar, 'update OK';

# update_insert 2.
ok $e->db->$table->update_insert('id', { id => 5, test => 'insert OK' });
ok $scalar= $e->db->$table->scalarref('test', 'id = ?', 5);
is $$scalar, 'insert OK';
ok $array = $e->db->$table->arrayref;
is scalar(@$array), 5;

# delete.
ok $e->db->$table->delete('id = ?', 5);
$scalar= $e->db->$table->scalarref('test', 'id = ?', 5) || 0;
ok ! $scalar;

# clear.
ok $e->db->$table->clear(1);
$array= $e->db->$table->arrayref || 0;
ok ! $array;

ok $dbh->do(qq{ DROP TABLE $table });

  };

