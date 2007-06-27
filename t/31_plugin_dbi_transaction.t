
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $dsn   = $ENV{EGG_RDBMS_DSN}        || "";
my $uid   = $ENV{EGG_RDBMS_USER}       || "";
my $psw   = $ENV{EGG_RDBMS_PASSWORD}   || "";
my $table = $ENV{EGG_RDBMS_TEST_TABLE} || 'egg_release_dbi_test_table';

SKIP: {
skip q{ Data base is not setup. }, 6 unless ($dsn and $uid);

eval{ require DBI };
skip q{ 'DBI' module is not installed. }, 6 if $@;

my $test= Egg::Helper::VirtualTest->new( prepare=> {
  controller=> { egg_includes=> [qw/ DBI::Transaction /] },
  config => {
    MODEL=> [[ DBI=> {
      dsn      => $dsn,
      user     => $uid,
      password => $psw,
      option   => { RaiseError=> 1, AutoCommit=> 0 },
      }]],
    },
  });

my $e;
eval{ $e= $test->egg_pcomp_context };
if ($@) {
	die $@;
	skip q{ Doesn't connect with the data base. }, 6;
}

can_ok $e,
   qw/ dbh rollback_ok commit_ok dbh_commit dbh_rollback is_autocommit /;
can_ok 'Egg::Plugin::DBI::Transaction',
   qw/ _finalize_error _finalize_result / unless $e->is_autocommit;

ok $e->commit_ok(1);
ok ! $e->rollback_ok;
ok ! $e->commit_ok(0);
ok $e->rollback_ok;

  };

