
use Test::More tests=> 13;
use Egg::Helper;
my $t= Egg::Helper->run('O:Test');
$t->prepare;
my $e   = $t->egg_virtual;
my $res = $e->response;
my $CRLF= $Egg::CRLF;

ok( $res->cookie( test=> { value=> 'hoge' } ) );
ok( $res->cookie('test') );
ok( $res->cookie('test')->{value} );
is $res->cookie('test')->{value}, 'hoge';
ok( $res->cookies->{test2}= { value=> 'hoge2' } );
ok( $res->cookies->{test2} );
ok( $res->cookies->{test2}{value} );
ok( my $out= $res->create_header );
like $$out, qr{\bSet\-Cookie\:\s+.*?test\=hoge\;.+?$CRLF}is;
like $$out, qr{\bSet\-Cookie\:\s+.*?test2\=hoge2\;.+?$CRLF}is;
$res->cookies->{test2}= 0;
ok( $out= $res->create_header );
like $$out, qr{\bSet\-Cookie\:\s+.*?test\=hoge\;.+?$CRLF}is;
ok( $$out=~m{\bSet\-Cookie\:\s+.*?test2\=hoge2\;.+?$CRLF}is ? 0: 1 );
