
use Test::More tests=> 15;
use Egg::Helper;
my $t= Egg::Helper->run('O:Test');
$t->create_project_root;
$t->prepare(
  config=> { log_file=> $t->project_root."/tmp/test_log" },
  );
my $e= $t->egg_virtual;
my $logfile= $e->config->{log_file};
my $message= 'Succeeded in output of log.';

ok( my $log= $e->log );
$log->{debug}= 0;
ok( ! $log->debug($message) );
ok( ! $@ );
ok( -e $logfile ? 0: 1 );
ok( $log->{debug}= 1 );
ok( ! $log->debug($message) );
ok( $t->read_file($logfile)=~/$message/ );
ok( unlink($logfile) );
ok( $log->notes($message) );
ok( -e $logfile );
ok( $t->read_file($logfile)=~/$message/ );
ok( unlink($logfile) );
$log->{debug}= 0;
ok( $log->notes($message) );
ok( -e $logfile );
ok( $t->read_file($logfile)=~/$message/ );
unlink($logfile);
