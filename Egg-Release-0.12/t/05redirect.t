
use Test::More tests => 8;
use IO::Scalar;
use lib 't';
use EggTest;
my $e= new EggTest;
my $res= $e->response;
my $out;

#0
ok( $res->redirect('/test') );
ok( $res->status );
ok( $res->status== 302 );
ok( $res->location );
like( $res->location, qr{^/test$} );

#5
ok( ! $e->finished );
tie *STDOUT, 'IO::Scalar', \$out;
$e->output_content;
untie *STDOUT;
like( $out, qr{Status\:\s+302}s );
like( $out, qr{Location\:\s+/test}s );
