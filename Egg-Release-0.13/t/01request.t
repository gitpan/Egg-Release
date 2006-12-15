
use Test::More tests => 17;
use lib 't';
use EggTest;
my $e = new EggTest;

$ENV{REMOTE_ADDR} = '192.168.1.1';
$ENV{HTTP_REFERER}= 'http://localdomain/test.test';
$ENV{HTTP_COOKIE} = 'build=test;';
$ENV{SCRIPT_NAME} = '/test/form';

#0
ok( my $req= $e->request );
ok( $req->prepare($e) );
ok( ref($req) eq 'Egg::Request::CGI' );
ok( $req->isa('Egg::Request') );
ok( ref($req->params) eq 'HASH' );

#5
ok( $req->param('test', 1) );
ok( $req->param('test')== 1 );
$req->params->{test}+= 2;
ok( $req->param('test')== 3 );
ok( ref($req->cookies) eq 'HASH' );
ok( my $cookie= $req->cookie('build') );

#10
ok( $cookie->value eq 'test' );
ok( $req->address eq $ENV{REMOTE_ADDR} );
ok( $req->scheme eq 'http' );
ok( $req->host eq '127.0.0.1' );
ok( $req->path=~m{^/test/form$} );

#15
ok( $req->server_port== 80 );
ok( $req->uri=~m{^http\://127.0.0.1/test/form$} );

