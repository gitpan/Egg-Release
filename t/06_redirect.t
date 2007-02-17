
use Test::More tests => 9; # qw/no_plan/
use Egg::Helper;
my $t= Egg::Helper->run('O:Test');
$t->prepare;
my $e   = $t->egg_virtual;
my $res = $e->response;
my $CRLF= $Egg::CRLF;

ok( $res->redirect('/test') );
ok( $res->status );
is $res->status, 302;
ok( $res->location );
like $res->location, qr{^/test$};
ok( ! $e->finished );
ok( my $catch= $t->catch_stdout( sub { $e->output_content } ) );
like $$catch, qr{\bStatus\:\s+302\s+Found$CRLF}s;
like $$catch, qr{\bLocation\:\s+/test$CRLF}s;
