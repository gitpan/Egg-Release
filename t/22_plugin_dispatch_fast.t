
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new;
$test->prepare( controller => {
  egg=> [qw/ Dispatch::Fast Log Debugging /],
  dispatch=> join('', <DATA>),
  });

my $e= $test->egg_pcomp_context;

ok my $dispatch= $e->dispatch;
isa_ok $dispatch, 'Egg::Plugin::Dispatch::Fast::handler';
ok my $run= $dispatch->run_modes;

ok $run->{_default};
ok $run->{test1};
ok $run->{test2};
ok $run->{test3};

isa_ok $run->{_default}, 'CODE';
isa_ok $run->{test1},    'CODE';
isa_ok $run->{test2},    'CODE';
isa_ok $run->{test3},    'CODE';

my($d, $flag);
my $reset= sub {
  $d= Egg::Plugin::Dispatch::Fast::handler->new($e);
  $flag= $d->{flag}= {};
  };

$reset->();
ok $d->_start;
ok $d->_action;
ok @{$d->action};
is join('/', @{$d->action}), 'index';
ok $d->_finish;

$reset->();
ok $d->mode('test1');
ok $d->_start;
ok $d->_action;
ok $flag->{test1};
ok @{$d->action};
is join('/', @{$d->action}), 'test1';

$reset->();
ok $d->mode('test2');
ok $d->_start;
ok $d->_action;
ok $e->finished;
ok $e->response->status;
is $e->response->status, 403;
ok @{$d->action};
is join('/', @{$d->action}), 'test2';

$reset->();
ok $d->mode('test3');
ok $d->_start;
ok $d->_action;
ok $e->template;
is $e->template, 'test3.tt';


__DATA__

 _default => sub {},
 test1    => sub { $_[1]->{flag}{test1}= 1 },
 test2    => sub { $_[0]->finished(403) },
 test3    => sub { $_[0]->template('test3.tt') },

