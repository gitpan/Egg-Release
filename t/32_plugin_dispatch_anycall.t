
use Test::More qw/no_plan/;
use Egg::Helper;
my $t= Egg::Helper->run('O:Test');

my @files= $t->yaml_load(join '', <DATA>);

my $run_modes= <<END_OF_RUN;
 test=> sub { \$_[1]->call_to('Test') },
END_OF_RUN

$t->prepare(
  controller=> { egg=> [qw/Dispatch::AnyCall/] },
  dispatch=> { run_modes=> $run_modes },
  create_files=> \@files,
  );

ok( my $e= $t->egg_virtual );
ok( $t->setup_env('http://domain.name/test/test') );

if (my $catch= $t->response_catch($e)) {
	is $e->response->status, 200;
	like $$catch, qr/test_ok/;
	ok( $e->{anycall_ok} );
}

__DATA__
---
filename: lib/<# project_name #>/D/Test.pm
value: |
  package <# project_name #>::D::Test;
  use strict;
  sub test {
  	my($dispatch, $e)= @_;
  	$e->{anycall_ok}= 1;
  	$e->response->body('test_ok');
  }
  1;
