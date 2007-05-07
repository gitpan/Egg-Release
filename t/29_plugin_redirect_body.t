
use Test::More tests => 6;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new( prepare=> {
  controller=> { egg_includes=> [qw/ Redirect::Body /] },
  });

ok my $e= $test->egg_context;
ok $e->redirect_body;
ok my $status= $e->response->status;
is $status, 302;
ok my $body= $e->response->body;
like $$body, qr{<meta +http\-equiv\=\"refresh\" +content\=\"\d+\;url\=.+?\" +/>}s;

