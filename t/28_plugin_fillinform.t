
use Test::More tests => 13;
use Egg::Helper::VirtualTest;

SKIP: {
eval{ require HTML::FillInForm };
skip q{ HTML::FillInForm is not installed. } if $@;

my $test= Egg::Helper::VirtualTest->new( prepare=> {
  controller=> { egg_includes=> [qw/ FillInForm /], },
  });

my $body= join '', <DATA>;
ok my $e= $test->egg_context;
ok $e->isa('Egg::Plugin::FillInForm');
can_ok $e, qw/ fillform _valid_error /;  # fillin_ok
ok my $req= $e->request;
isa_ok $req, 'Egg::Request::CGI';
ok $req->param( test1 => 'test_ok1' );
ok $req->param( test2 => '1' );
ok $req->param( test3 => '1' );
ok $e->fillform( \$body );
ok $body= $e->response->body;

my $check_code= sub {
	my($key, $value)= @_;
	for (split /\n/, $$body) {
		/name=\"$key\"/    || next;
		/value=\"$value\"/ || next;
		/type=\"text\"/       and return 1;
		/checked=\"checked\"/
		  and ( /type=\"checkbox\"/ or /type=\"radio\"/ )
		    and return 1;
	}
  };

ok $check_code->( test1 => 'test_ok1' );
ok $check_code->( test2 => '1' );
ok $check_code->( test3 => '1' );

  };

__DATA__
<html>
<body>
<form method="POST" action="/">
<input type="text" name="test1" />
<input type="checkbox" name="test2" value="1" />
<input type="radio" name="test3" value="1" />
</form>
</body>
</html>
