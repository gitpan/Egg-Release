
use Test::More qw/no_plan/;
use Egg::Helper;
my $t= Egg::Helper->run('O:Test');
$t->create_project_root;
my $project_name= $t->project_name;
my $hash= $t->yaml_load(join '', <DATA>);

$t->prepare(
  dispatch=> {
    extend_codes_first=> "use $project_name\::D::Test;",
    run_modes=> $hash->{run_modes},
    },
  create_files=> [$hash->{dispatch}],
  );

ok( my $e= $t->egg_virtual );
ok( $e->prepare_component );
ok( -e $t->project_root."/lib/$project_name/D/Test.pm" );
ok( my $dis= $e->dispatch );
ok( my $run= $dis->run_modes );
isa_ok $run, 'HASH';
isa_ok $run->{_default}, 'CODE';
isa_ok $run->{test}, 'HASH';
ok( (grep{ref($_) eq 'HASH'}keys %{$run->{test}})== 2 );
ok( my $flag= $e->dispatch->{flag}= {} );

my $reset= sub {
	$e->request->{is_get}= $e->request->{is_post}= 0;
	%{$flag}= ();
  };

$reset->();
ok( ! $e->dispatch->_start );
ok( $e->dispatch->_action );
ok( @{$e->action} );
is join('/', @{$e->action}), 'index';
ok( ! $e->dispatch->_finish );

$reset->();
ok( $e->dispatch->{snip}= [qw/test/] );
ok( $e->dispatch->_start );
ok( $flag->{test_begin_ok} );
ok( $e->dispatch->_action );
ok( $e->template );
is $e->template, 'test.tt';
ok( $e->dispatch->_finish );
ok( $flag->{test_end_ok} );

$reset->();
ok( $e->dispatch->{snip}= [qw/test test2/] );
ok( $e->dispatch->_start );
ok( ! $flag->{test_begin_ok} );
ok( $flag->{test_test_begin_ok} );
ok( $e->dispatch->_action );
is $e->response->status, 403;
ok( ! $e->finished(0) );
ok( ! $e->response->status );
ok( $e->dispatch->_finish );
ok( ! $flag->{test_end_ok} );
ok( $flag->{test_test_end_ok} );
ok( $e->dispatch->mode_now );
is $e->dispatch->mode_now, 'test-test2';
is $e->dispatch->mode_now(1), 'test';
is $e->dispatch->mode_now(2), '';
isa_ok $e->dispatch->label, 'ARRAY';
is @{$e->dispatch->label}, 2;
ok( ! $e->dispatch->label->[2] );
is $e->dispatch->label->[1], 'test_page';
is $e->dispatch->label->[0], 'test';
ok( $e->dispatch->page_title );
is $e->dispatch->page_title, 'test_page';

$reset->();
ok( $e->dispatch->{snip}= [qw/test test2 foo123/] );
ok( $e->dispatch->_start );
ok( ! $flag->{test_begin_ok} );
ok( $flag->{test_test_begin_ok} );
ok( $e->dispatch->_action );
ok( $flag->{test_test_foo_ok} );
is $flag->{test_test_foo_ok}, 123;
is join('/', @{$e->action}), 'test/test2/foo123';
ok( $e->dispatch->_finish );
ok( ! $flag->{test_end_ok} );
ok( $flag->{test_test_end_ok} );
ok( $e->dispatch->mode_now );
is $e->dispatch->mode_now, 'test-test2-foo123';
is $e->dispatch->mode_now(1), 'test-test2';
is $e->dispatch->mode_now(2), 'test';
is $e->dispatch->mode_now(3), '';
isa_ok $e->dispatch->label, 'ARRAY';
is @{$e->dispatch->label}, 3;
is $e->dispatch->label->[2], 'foo123';
is $e->dispatch->label->[1], 'test_page';
is $e->dispatch->label->[0], 'test';
ok( $e->dispatch->page_title );
is $e->dispatch->page_title, 'foo123';

$reset->();
ok( $e->dispatch->{snip}= [qw/test test2 hogeabc/] );
ok( $e->dispatch->_start );
ok( ! $flag->{test_begin_ok} );
ok( $flag->{test_test_begin_ok} );
ok( $e->dispatch->_action );
ok( $flag->{test_test_hoge_ok} );
is $flag->{test_test_hoge_ok}, 'abc';
is join('/', @{$e->action}), 'test/test2/hogeabc';
ok( $e->dispatch->_finish );
ok( ! $flag->{test_end_ok} );
ok( $flag->{test_test_end_ok} );
ok( $e->dispatch->mode_now );
is $e->dispatch->mode_now, 'test-test2-hogeabc';
is $e->dispatch->mode_now(1), 'test-test2';
is $e->dispatch->mode_now(2), 'test';
is $e->dispatch->mode_now(3), '';
isa_ok $e->dispatch->label, 'ARRAY';
is @{$e->dispatch->label}, 3;
is $e->dispatch->label->[2], 'hogeabc';
is $e->dispatch->label->[1], 'test_page';
is $e->dispatch->label->[0], 'test';
ok( $e->dispatch->page_title );
is $e->dispatch->page_title, 'hogeabc';

$reset->();
$e->action([]);
ok( $e->template('none') );
ok( $e->dispatch->{snip}= [qw/test form/] );
ok( $e->dispatch->_start );
ok( $flag->{test_begin_ok} );
ok( ! $flag->{test_test_begin_ok} );
ok( ! $flag->{test_form_begin_ok} );
ok( $e->dispatch->_action );
ok( ! $flag->{test_form_default_ok} );
is join('/', @{$e->action}), 'test/index';
is $e->template, 'test.tt';
ok( $e->dispatch->_finish );
ok( $flag->{test_end_ok} );
ok( ! $flag->{test_test_end_ok} );
ok( ! $flag->{test_form_end_ok} );
ok( $e->dispatch->mode_now );
is $e->dispatch->mode_now, 'test';
is $e->dispatch->mode_now(1), '';
isa_ok $e->dispatch->label, 'ARRAY';
is @{$e->dispatch->label}, 1;
ok( ! $e->dispatch->label->[1] );
is $e->dispatch->label->[0], 'test';
ok( $e->dispatch->page_title );
is $e->dispatch->page_title, 'test';

$reset->();
$e->request->{is_post}= 1;
$e->action([]);
ok( $e->template('none') );
ok( $e->dispatch->{snip}= [qw/test form/] );
ok( $e->dispatch->_start );
ok( ! $flag->{test_begin_ok} );
ok( ! $flag->{test_test_begin_ok} );
ok( $flag->{test_form_begin_ok} );
ok( $e->dispatch->_action );
ok( $flag->{test_form_default_ok} );
is join('/', @{$e->action}), 'test/form/index';
ok( $e->dispatch->_finish );
ok( ! $flag->{test_end_ok} );
ok( ! $flag->{test_test_end_ok} );
ok( $flag->{test_form_end_ok} );
ok( $e->dispatch->mode_now );
is $e->dispatch->mode_now, 'test-form';
is $e->dispatch->mode_now(1), 'test';
is $e->dispatch->mode_now(2), '';
isa_ok $e->dispatch->label, 'ARRAY';
is @{$e->dispatch->label}, 2;
ok( ! $e->dispatch->label->[2] );
is $e->dispatch->label->[1], 'test_form';
is $e->dispatch->label->[0], 'test';
ok( $e->dispatch->page_title );
is $e->dispatch->page_title, 'test_form';

$reset->();
$e->request->{is_post}= 1;
$e->action([]);
ok( $e->dispatch->{snip}= [qw/test form boo/] );
ok( $e->dispatch->_start );
ok( $flag->{test_form_begin_ok} );
ok( $e->dispatch->_action );
ok( $flag->{test_form_boo_ok} );
is join('/', @{$e->action}), 'test/form/boo';
ok( $e->dispatch->_finish );
ok( $flag->{test_form_end_ok} );
ok( $e->dispatch->mode_now );
is $e->dispatch->mode_now, 'test-form-boo';
is $e->dispatch->mode_now(1), 'test-form';
is $e->dispatch->mode_now(2), 'test';
is $e->dispatch->mode_now(3), '';
isa_ok $e->dispatch->label, 'ARRAY';
is @{$e->dispatch->label}, 3;
ok( ! $e->dispatch->label->[3] );
is $e->dispatch->label->[2], 'boo';
is $e->dispatch->label->[1], 'test_form';
is $e->dispatch->label->[0], 'test';
ok( $e->dispatch->page_title );
is $e->dispatch->page_title, 'boo';

$reset->();
ok( $e->dispatch->{snip}= [qw/test banban/] );
ok( $e->dispatch->_start );
ok( $flag->{test_begin_ok} );
ok( $e->dispatch->_action );
is $e->template, 'banban/index.tt';
is join('/', @{$e->action}), 'test/banban';
ok( $e->dispatch->_finish );
ok( $flag->{test_end_ok} );
ok( $e->dispatch->mode_now );
is $e->dispatch->mode_now, 'test-banban';
is $e->dispatch->mode_now(1), 'test';
is $e->dispatch->mode_now(2), '';
isa_ok $e->dispatch->label, 'ARRAY';
is @{$e->dispatch->label}, 2;
ok( ! $e->dispatch->label->[2] );
is $e->dispatch->label->[1], 'banban';
is $e->dispatch->label->[0], 'test';
ok( $e->dispatch->page_title );
is $e->dispatch->page_title, 'banban';


__DATA__
dispatch:
 filename: lib/<# project_name #>/D/Test.pm
 value: |
  package <# project_name #>::D::Test;
  use strict;
  sub boo {
  	my($dispatch, $e)= @_;
  	$dispatch->{flag}{test_form_boo_ok}= 1;
  }
  1;
run_modes: |
 _default=> sub { },
 test=> refhash(
   _begin  => sub { $_[0]->{flag}{test_begin_ok}= 1 },
   _end    => sub { $_[0]->{flag}{test_end_ok}  = 1 },
   _default=> sub { $_[1]->template('test.tt') },
   { ANY=> 'test2', label=> 'test_page' }=> refhash(
     _begin  => sub { $_[0]->{flag}{test_test_begin_ok}= 1 },
     _end    => sub { $_[0]->{flag}{test_test_end_ok}  = 1 },
     _default=> sub { $_[1]->finished(403) },
     qr/^foo(\d+)/ => sub { $_[0]->{flag}{test_test_foo_ok} = $_[2]->[0] },
     qr/^hoge(\w+)/=> sub { $_[0]->{flag}{test_test_hoge_ok}= $_[2]->[0] },
     ),
   { POST=> 'form', label=> 'test_form' }=> {
     _begin  => sub { $_[0]->{flag}{test_form_begin_ok}  = 1 },
     _end    => sub { $_[0]->{flag}{test_form_end_ok}    = 1 },
     _default=> sub { $_[0]->{flag}{test_form_default_ok}= 1 },
     boo => \&<# project_name #>::D::Test::boo,
     },
   banban=> sub { $_[1]->template('banban/index.tt') },
   ),
