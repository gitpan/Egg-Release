use Test::More tests => 166;
use lib qw( ../lib ./lib );
use Egg::Helper;

$ENV{VTEST_DISPATCH_CLASS}= 'Egg::Dispatch::Standard';

my $e= Egg::Helper->run('Vtest');

can_ok $e, 'refhash';
  ok my $rh= $e->can('refhash')->({}), q{my $rh= $e->can('refhash')->({})};
  isa_ok $rh, 'HASH';
  isa_ok tied(%$rh), 'Tie::RefHash';

can_ok $e, 'dispatch_map';
ok $e->dispatch_map({
 _default => sub { },
 test => {
  _begin   => sub { $_[1]->{flag}{test_begin_ok}= 1 },
  _end     => sub { $_[1]->{flag}{test_end_ok}  = 1 },
  _default => sub { $_[0]->template('test.tt') },
  test2=> {
    _begin         => sub { $_[1]->{flag}{test_test_begin_ok}= 1 },
    _end           => sub { $_[1]->{flag}{test_test_end_ok}  = 1 },
    _default       => sub { $_[0]->finished(403) },
    qr/^foo(\d+)/  => sub { $_[1]->{flag}{test_test_foo_ok} = $_[2]->[0] },
    qr/^hoge(\w+)/ => sub { $_[1]->{flag}{test_test_hoge_ok}= $_[2]->[0] },
    },
  test3=> {
    _begin => sub { $_[1]->{flag}{test_test3_begin_ok}= 1 },
    },
  banban => sub { $_[0]->template('banban/index.tt') },
  },
 }), q{$e->dispatch_map( .......... };

ok my $map= $e->dispatch_map, q{my $map= $e->dispatch_map};

ok $map->{_default}, q{$map->{_default}};
ok $map->{test}, q{$map->{test}};
isa_ok $map->{_default}, 'CODE';
isa_ok $map->{test}, 'HASH';
ok $map->{test}{_begin}, q{$map->{test}{_begin}};
ok $map->{test}{_end}, q{$map->{test}{_end}};
ok $map->{test}{_default}, q{$map->{test}{_default}};
ok $map->{test}{test2}, q{$map->{test}{test2}};
ok $map->{test}{test3}, q{$map->{test}{test3}};
ok $map->{test}{banban}, q{$map->{test}{banban}};

isa_ok $map->{test}{_begin}, 'CODE';
isa_ok $map->{test}{_end}, 'CODE';
isa_ok $map->{test}{_default}, 'CODE';
isa_ok $map->{test}{test2}, 'HASH';
isa_ok $map->{test}{test3}, 'HASH';
isa_ok $map->{test}{banban}, 'CODE';
ok $map->{test}{test2}{_begin}, q{$map->{test}{test2}{_begin}};
ok $map->{test}{test2}{_end}, q{$map->{test}{test2}{_end}};
ok $map->{test}{test2}{_default}, q{$map->{test}{test2}{_default}};
isa_ok $map->{test}{test2}{_begin}, 'CODE';
isa_ok $map->{test}{test2}{_end}, 'CODE';
isa_ok $map->{test}{test2}{_default}, 'CODE';
ok $map->{test}{test3}{_begin}, q{$map->{test}{test3}{_begin}};
isa_ok $map->{test}{test3}{_begin}, 'CODE';

can_ok $e, 'dispatch';
 ok my $dispatch= $e->dispatch, q{my $dispatch= $e->dispatch};
 isa_ok $dispatch, 'Egg::Dispatch::Standard::handler';

my($d, $flag);
my $reset= sub {
  $d= Egg::Dispatch::Standard::handler->new($e);
  $flag= $d->{flag}= {};
  };

$reset->();
ok ! $d->_start, q{! $d->_start};
ok $d->_action, q{$d->_action};
ok @{$d->action}, q{@{$d->action}};
is join('/', @{$d->action}), 'index', q{join('/', @{$d->action}), 'index'};
ok ! $d->_finish, q{! $d->_finish};

$reset->();
ok $d->_snip([qw/test/]), q{$d->_snip([qw/test/])};
ok $d->_start, q{$d->_start};
ok $flag->{test_begin_ok}, q{$flag->{test_begin_ok}};
ok $d->_action, q{$d->_action};
ok $e->template, q{$e->template};
is $e->template, 'test.tt', q{$e->template, 'test.tt'};
ok $d->_finish, q{$d->_finish};
ok $flag->{test_end_ok}, q{$flag->{test_end_ok}};

$reset->();
ok ! $flag->{test_begin_ok}, q{! $flag->{test_begin_ok}};
ok ! $flag->{test_test_begin_ok}, q{! $flag->{test_test_begin_ok}};
ok $d->_snip([qw/test test2/]), q{$d->_snip([qw/test test2/])};
ok $d->_start, q{$d->_start};
ok ! $flag->{test_begin_ok}, q{! $flag->{test_begin_ok}};
ok $flag->{test_test_begin_ok}, q{$flag->{test_test_begin_ok}};
ok $d->_action, q{$d->_action};
is $e->response->status, 403, q{$e->response->status, 403};
ok ! $e->finished(0), q{! $e->finished(0)};
ok ! $e->response->status, q{! $e->response->status};
ok $d->_finish, q{$d->_finish};
ok ! $flag->{test_end_ok}, q{! $flag->{test_end_ok}};
ok $flag->{test_test_end_ok}, q{$flag->{test_test_end_ok}};
ok $d->mode_now, q{$d->mode_now};
is $d->mode_now, 'test/test2', q{$d->mode_now, 'test/test2'};
is $d->mode_now(1), 'test', q{$d->mode_now(1), 'test'};
is $d->mode_now(2), '', q{$d->mode_now(2), ''};
isa_ok $d->label, 'ARRAY';
is @{$d->label}, 2, q{@{$d->label}, 2};
is $d->label->[0], 'test', q{$d->label->[0], 'test'};
is $d->label->[1], 'test2', q{$d->label->[1], 'test2'};
ok $d->page_title, q{$d->page_title};
is $d->page_title, 'test2', q{$d->page_title, 'test2'};

$reset->();
ok $d->_snip([qw/test test2 foo123/]), q{$d->_snip([qw/test test2 foo123/])};
ok $d->_start, q{$d->_start};
ok ! $flag->{test_begin_ok}, q{! $flag->{test_begin_ok}};
ok $flag->{test_test_begin_ok}, q{$flag->{test_test_begin_ok}};
ok $d->_action, q{$d->_action};
ok $flag->{test_test_foo_ok}, q{$flag->{test_test_foo_ok}};
is $flag->{test_test_foo_ok}, 123, q{$flag->{test_test_foo_ok}, 123};
is join('/', @{$d->action}), 'test/test2/foo123', q{join('/', @{$d->action}), 'test/test2/foo123'};
ok $d->_finish, q{$d->_finish};
ok ! $flag->{test_end_ok}, q{! $flag->{test_end_ok}};
ok $flag->{test_test_end_ok}, q{$flag->{test_test_end_ok}};
ok $d->mode_now, q{$d->mode_now};
is $d->mode_now, 'test/test2/foo123', q{$d->mode_now, 'test/test2/foo123'};
is $d->mode_now(1), 'test/test2', q{$d->mode_now(1), 'test/test2'};
is $d->mode_now(2), 'test', q{$d->mode_now(2), 'test'};
is $d->mode_now(3), '', q{$d->mode_now(3), ''};
isa_ok $d->label, 'ARRAY';
is @{$d->label}, 3, q{@{$d->label}, 3};
is $d->label->[0], 'test', q{$d->label->[0], 'test'};
is $d->label->[1], 'test2', q{$d->label->[1], 'test2'};
is $d->label->[2], 'foo123', q{$d->label->[2], 'foo123'};
ok $d->page_title, q{$d->page_title};
is $d->page_title, 'foo123', q{$d->page_title, 'foo123'};

$reset->();
ok $d->_snip([qw/test test2 hogeabc/]), q{$d->_snip([qw/test test2 hogeabc/])};
ok $d->_start, q{$d->_start};
ok ! $flag->{test_begin_ok}, q{! $flag->{test_begin_ok}};
ok $flag->{test_test_begin_ok}, q{$flag->{test_test_begin_ok}};
ok $d->_action, q{$d->_action};
ok $flag->{test_test_hoge_ok}, q{$flag->{test_test_hoge_ok}};
is $flag->{test_test_hoge_ok}, 'abc', q{$flag->{test_test_hoge_ok}, 'abc'};
is join('/', @{$d->action}), 'test/test2/hogeabc', q{join('/', @{$d->action}), 'test/test2/hogeabc'};
ok $d->_finish, q{$d->_finish};
ok ! $flag->{test_end_ok}, q{! $flag->{test_end_ok}};
ok $flag->{test_test_end_ok}, q{$flag->{test_test_end_ok}};
ok $d->mode_now, q{$d->mode_now};
is $d->mode_now, 'test/test2/hogeabc', q{$d->mode_now, 'test/test2/hogeabc'};
is $d->mode_now(1), 'test/test2', q{$d->mode_now(1), 'test/test2'};
is $d->mode_now(2), 'test', q{$d->mode_now(2), 'test'};
is $d->mode_now(3), '', q{$d->mode_now(3), ''};
isa_ok $d->label, 'ARRAY';
is @{$d->label}, 3, q{@{$d->label}, 3};
is $d->label->[2], 'hogeabc', q{$d->label->[2], 'hogeabc'};
is $d->label->[1], 'test2', q{$d->label->[1], 'test2'};
is $d->label->[0], 'test', q{$d->label->[0], 'test'};
ok $d->page_title, q{$d->page_title};
is $d->page_title, 'hogeabc', q{$d->page_title, 'hogeabc'};

$reset->();
ok $e->action([]), q{$e->action([])};
ok $e->template('none'), q{$e->template('none')};
ok $d->_snip([qw/test form/]), q{$d->_snip([qw/test form/])};
ok $d->_start, q{$d->_start};
ok $flag->{test_begin_ok}, q{$flag->{test_begin_ok}};
ok ! $flag->{test_test_begin_ok}, q{! $flag->{test_test_begin_ok}};
ok ! $flag->{test_form_begin_ok}, q{! $flag->{test_form_begin_ok}};
ok $d->_action, q{$d->_action};
ok ! $flag->{test_form_default_ok}, q{! $flag->{test_form_default_ok}};
is join('/', @{$d->action}), 'test/index', q{join('/', @{$d->action}), 'test/index'};
is $e->template, 'test.tt', q{$e->template, 'test.tt'};
ok $d->_finish, q{$d->_finish};
ok $flag->{test_end_ok}, q{$flag->{test_end_ok}};
ok ! $flag->{test_test_end_ok}, q{! $flag->{test_test_end_ok}};
ok ! $flag->{test_form_end_ok}, q{! $flag->{test_form_end_ok}};
ok $d->mode_now, q{$d->mode_now};
is $d->mode_now, 'test', q{$d->mode_now, 'test'};
is $d->mode_now(1), '', q{$d->mode_now(1), ''};
isa_ok $d->label, 'ARRAY';
is @{$d->label}, 1, q{@{$d->label}, 1};
ok ! $d->label->[1], q{! $d->label->[1]};
is $d->label->[0], 'test', q{$d->label->[0], 'test'};
ok $d->page_title, q{$d->page_title};
is $d->page_title, 'test', q{$d->page_title, 'test'};

$reset->();
ok $d->_snip([qw/test test3/]), q{$d->_snip([qw/test test3/])};
ok $d->_start, q{$d->_start};
ok $flag->{test_test3_begin_ok}, q{$flag->{test_test3_begin_ok}};
ok $d->_action, q{$d->_action};
is $e->template, 'test.tt', q{$e->template, 'test.tt'};
ok $d->_finish, q{$d->_finish};
ok $flag->{test_end_ok}, q{$flag->{test_end_ok}};

$reset->();
ok $d->_snip([qw/test banban/]), q{$d->_snip([qw/test banban/])};
ok $d->_start, q{$d->_start};
ok $flag->{test_begin_ok}, q{$flag->{test_begin_ok}};
ok $d->_action, q{$d->_action};
is $e->template, 'banban/index.tt', q{$e->template, 'banban/index.tt'};
is join('/', @{$d->action}), 'test/banban', q{join('/', @{$d->action}), 'test/banban'};
ok $d->_finish, q{$d->_finish};
ok $flag->{test_end_ok}, q{$flag->{test_end_ok}};
ok $d->mode_now, q{$d->mode_now};
is $d->mode_now, 'test/banban', q{$d->mode_now, 'test/banban'};
is $d->mode_now(1), 'test', q{$d->mode_now(1), 'test'};
is $d->mode_now(2), '', q{$d->mode_now(2), ''};
isa_ok $d->label, 'ARRAY';
is @{$d->label}, 2, q{@{$d->label}, 2};
ok ! $d->label->[2], q{! $d->label->[2]};
is $d->label->[1], 'banban', q{$d->label->[1], 'banban'};
is $d->label->[0], 'test', q{$d->label->[0], 'test'};
ok $d->page_title, q{$d->page_title};
is $d->page_title, 'banban', q{$d->page_title, 'banban'};

