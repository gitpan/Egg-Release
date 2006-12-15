
use Test::More tests=> 8;
use lib 't';
use Egg::Helper::Test;
use EggTest;
my $et = new Egg::Helper::Test;
my $e  = new EggTest;
my $tmp= $et->temp;

my $logfile= $e->config->{log_file}= "$tmp/test_log";
my $message= 'Succeeded in output of log.';

#0
ok( my $log= $e->log );

$log->{debug}= 0;
$log->debug($message);
ok( -e $logfile ? 0: 1 );

$log->{debug}= 1;
$log->debug($message);
ok( -e $logfile );
ok( $et->read_file($logfile)=~/$message/ );
unlink($logfile);

$log->notes($message);
ok( -e $logfile );

#5
ok( $et->read_file($logfile)=~/$message/ );
unlink($logfile);

$log->{debug}= 0;
$log->notes($message);
ok( -e $logfile );
ok( $et->read_file($logfile)=~/$message/ );
unlink($logfile);
