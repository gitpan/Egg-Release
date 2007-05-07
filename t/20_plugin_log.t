
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;
use FileHandle;

$SIG{__WARN__}= sub {};

my $test= Egg::Helper::VirtualTest->new;
   $test->prepare( config=> { log_file=> '< $e.dir.tmp >/test.log', } );
my $e= $test->egg_context;

ok my $file= $e->config->{log_file};
ok my $log = $e->log;
isa_ok $log, 'Egg::Plugin::Log::handler';
can_ok $log, qw/ new notes debug error _log _line /;
ok $log->notes('test1');
ok $log->debug('test2');
ok $log->error('test3');
ok my $body= $e->{log_body};
like $body, qr{\b.+?\[notes\] +.+?test1};
like $body, qr{\b.+?\[debug\] +.+?test2};
like $body, qr{\b.+?\[error\] +.+?test3};

