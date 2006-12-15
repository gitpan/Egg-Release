
use Test::More tests=> 20;
use IO::Scalar;
use lib 't';
use EggTest;
my $e= new EggTest;
my $res= $e->response;
my $out;

#0
ok( $res->cookie( test=> { value=> 'hoge' } ) );
ok( $res->cookie('test') );
ok( ref($res->cookie('test')) eq 'Egg::Response::TieCookie::Params' );
ok( $res->cookie('test')->{value} );
ok( $res->cookie('test')->{value} eq 'hoge' );

#5
ok( $res->cookie('test')->value eq 'hoge' );
ok( $res->cookie('test')->plain_value eq 'hoge' );
ok( $res->cookies->{test2}= { value=> 'hoge2' } );
ok( $res->cookies->{test2} );
ok( ref($res->cookies->{test2}) eq 'Egg::Response::TieCookie::Params' );

#10
ok( $res->cookies->{test2}{value} );
ok( $res->cookies->{test2}->value eq 'hoge2' );
$out= $res->create_header;
like( $$out, qr{Set\-Cookie\:\s+.*?test\=hoge}is );
like( $$out, qr{Set\-Cookie\:\s+.*?test2\=hoge2}is );
$res->cookies->{test2}= 0;
$out= $res->create_header;
like( $$out, qr{Set\-Cookie\:\s+.*?test\=hoge}is );

#15
ok( $$out=~/Set\-Cookie\:\s+.*?test2\=hoge2/is ? 0: 1 );
ok( $res->redirect('/foo') );
undef($out);
tie *STDOUT, 'IO::Scalar', \$out;
$e->output_content;
untie *STDOUT;
like( $out, qr{Set\-Cookie\:\s+.*?test\=hoge}is );
like( $out, qr{Status\:\s+302}s );
like( $out, qr{Location\:\s+/foo}s );

#20
