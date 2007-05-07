
use Test::More tests => 158;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new;
$test->prepare( controller=> { dispatch=> join('', <DATA>) } );

my $e= $test->egg_pcomp_context;

ok my $dispatch= $e->dispatch;
isa_ok $dispatch, 'Egg::Plugin::Dispatch::Standard::handler';
ok my $run= $dispatch->run_modes;

ok $run->{_default};
ok $run->{test};

isa_ok $run->{_default}, 'CODE';
isa_ok $run->{test}, 'HASH';

ok $run->{test}{_begin};
ok $run->{test}{_end};
ok $run->{test}{_default};
ok $run->{test}{test2};
ok $run->{test}{test3};
ok $run->{test}{banban};

isa_ok $run->{test}{_begin}, 'CODE';
isa_ok $run->{test}{_end}, 'CODE';
isa_ok $run->{test}{_default}, 'CODE';
isa_ok $run->{test}{test2}, 'HASH';
isa_ok $run->{test}{test3}, 'HASH';
isa_ok $run->{test}{banban}, 'CODE';

ok $run->{test}{test2}{_begin};
ok $run->{test}{test2}{_end};
ok $run->{test}{test2}{_default};

isa_ok $run->{test}{test2}{_begin}, 'CODE';
isa_ok $run->{test}{test2}{_end}, 'CODE';
isa_ok $run->{test}{test2}{_default}, 'CODE';

ok $run->{test}{test3}{_begin};

isa_ok $run->{test}{test3}{_begin}, 'CODE';

my($d, $flag);
my $reset= sub {
  $d= Egg::Plugin::Dispatch::Standard::handler->new($e);
  $flag= $d->{flag}= {};
  };

$reset->();
ok ! $d->_start;
ok $d->_action;
ok @{$d->action};
is join('/', @{$d->action}), 'index';
ok ! $d->_finish;

$reset->();
ok $d->_snip([qw/test/]);
ok $d->_start;
ok $flag->{test_begin_ok};
ok $d->_action;
ok $e->template;
is $e->template, 'test.tt';
ok $d->_finish;
ok $flag->{test_end_ok};

$reset->();
ok ! $flag->{test_begin_ok};
ok ! $flag->{test_test_begin_ok};
#ok $d->{}
ok $d->_snip([qw/test test2/]);
ok $d->_start;
ok ! $flag->{test_begin_ok};
ok $flag->{test_test_begin_ok};
ok $d->_action;
is $e->response->status, 403;
ok ! $e->finished(0);
ok ! $e->response->status;
ok $d->_finish;
ok ! $flag->{test_end_ok};
ok $flag->{test_test_end_ok};
ok $d->mode_now;
is $d->mode_now, 'test/test2';
is $d->mode_now(1), 'test';
is $d->mode_now(2), '';
isa_ok $d->label, 'ARRAY';
is @{$d->label}, 2;
is $d->label->[0], 'test';
is $d->label->[1], 'test2';
ok $d->page_title;
is $d->page_title, 'test2';

$reset->();
ok $d->_snip([qw/test test2 foo123/]);
ok $d->_start;
ok ! $flag->{test_begin_ok};
ok $flag->{test_test_begin_ok};
ok $d->_action;
ok $flag->{test_test_foo_ok};
is $flag->{test_test_foo_ok}, 123;
is join('/', @{$d->action}), 'test/test2/foo123';
ok $d->_finish;
ok ! $flag->{test_end_ok};
ok $flag->{test_test_end_ok};
ok $d->mode_now;
is $d->mode_now, 'test/test2/foo123';
is $d->mode_now(1), 'test/test2';
is $d->mode_now(2), 'test';
is $d->mode_now(3), '';
isa_ok $d->label, 'ARRAY';
is @{$d->label}, 3;
is $d->label->[0], 'test';
is $d->label->[1], 'test2';
is $d->label->[2], 'foo123';
ok $d->page_title;
is $d->page_title, 'foo123';

$reset->();
ok $d->_snip([qw/test test2 hogeabc/]);
ok $d->_start;
ok ! $flag->{test_begin_ok};
ok $flag->{test_test_begin_ok};
ok $d->_action;
ok $flag->{test_test_hoge_ok};
is $flag->{test_test_hoge_ok}, 'abc';
is join('/', @{$d->action}), 'test/test2/hogeabc';
ok $d->_finish;
ok ! $flag->{test_end_ok};
ok $flag->{test_test_end_ok};
ok $d->mode_now;
is $d->mode_now, 'test/test2/hogeabc';
is $d->mode_now(1), 'test/test2';
is $d->mode_now(2), 'test';
is $d->mode_now(3), '';
isa_ok $d->label, 'ARRAY';
is @{$d->label}, 3;
is $d->label->[2], 'hogeabc';
is $d->label->[1], 'test2';
is $d->label->[0], 'test';
ok $d->page_title;
is $d->page_title, 'hogeabc';

$reset->();
$e->action([]);
ok $e->template('none');
ok $d->_snip([qw/test form/]);
ok $d->_start;
ok $flag->{test_begin_ok};
ok ! $flag->{test_test_begin_ok};
ok ! $flag->{test_form_begin_ok};
ok $d->_action;
ok ! $flag->{test_form_default_ok};
is join('/', @{$d->action}), 'test/index';
is $e->template, 'test.tt';
ok $d->_finish;
ok $flag->{test_end_ok};
ok ! $flag->{test_test_end_ok};
ok ! $flag->{test_form_end_ok};
ok $d->mode_now;
is $d->mode_now, 'test';
is $d->mode_now(1), '';
isa_ok $d->label, 'ARRAY';
is @{$d->label}, 1;
ok ! $d->label->[1];
is $d->label->[0], 'test';
ok $d->page_title;
is $d->page_title, 'test';

$reset->();
ok $d->_snip([qw/test test3/]);
ok $d->_start;
ok $flag->{test_test3_begin_ok};
ok $d->_action;
is $e->template, 'test.tt';
ok $d->_finish;
ok $flag->{test_end_ok};

$reset->();
ok $d->_snip([qw/test banban/]);
ok $d->_start;
ok $flag->{test_begin_ok};
ok $d->_action;
is $e->template, 'banban/index.tt';
is join('/', @{$d->action}), 'test/banban';
ok $d->_finish;
ok $flag->{test_end_ok};
ok $d->mode_now;
is $d->mode_now, 'test/banban';
is $d->mode_now(1), 'test';
is $d->mode_now(2), '';
isa_ok $d->label, 'ARRAY';
is @{$d->label}, 2;
ok ! $d->label->[2];
is $d->label->[1], 'banban';
is $d->label->[0], 'test';
ok $d->page_title;
is $d->page_title, 'banban';


__DATA__

_default => sub { },

test => {
  _begin   => sub { $_[0]->{flag}{test_begin_ok}= 1 },
  _end     => sub { $_[0]->{flag}{test_end_ok}  = 1 },
  _default => sub { $_[1]->template('test.tt') },
  test2=> {
    _begin         => sub { $_[0]->{flag}{test_test_begin_ok}= 1 },
    _end           => sub { $_[0]->{flag}{test_test_end_ok}  = 1 },
    _default       => sub { $_[1]->finished(403) },
    qr/^foo(\d+)/  => sub { $_[0]->{flag}{test_test_foo_ok} = $_[2]->[0] },
    qr/^hoge(\w+)/ => sub { $_[0]->{flag}{test_test_hoge_ok}= $_[2]->[0] },
    },
  test3=> {
    _begin => sub { $_[0]->{flag}{test_test3_begin_ok}= 1 },
    },
  banban => sub { $_[1]->template('banban/index.tt') },
  },

