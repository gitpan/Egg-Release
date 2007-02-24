
use Test::More qw/no_plan/;
use Egg::Helper;
eval "use HTML::FillInForm";
plan skip_all => "HTML::FillInForm required for testing plugin." if $@;

my $t= Egg::Helper->run('O:Test');

my @files= $t->yaml_load(join '', <DATA>);

my $run_modes= <<END_OF_RUN;
 _default=> sub {},
END_OF_RUN

$t->prepare(
  controller=> { egg=> [qw/FillInForm/] },
  dispatch=> { run_modes=> $run_modes },
  create_files=> \@files,
  );

ok( my $e= $t->egg_virtual );
ok( $e->prepare_component );
ok( my $param= $e->request->params );
ok( $param->{test1}= 'a1' );
ok( $param->{test2}= 'a2' );
ok( $param->{test3}= 'a3' );
ok( $param->{test4}= '1' );
ok( $param->{test5}= 'foo' );
ok( $param->{test6}= 'a6' );
ok( $e->fillin_ok(1) );
ok( $t->setup_env('http://domain.name/') );

if (my $catch= $t->response_catch2($e)) {
	like $$catch, qr#<html>.+?</html>#s;
	my $str;

	($str)= $$catch=~m#<input (.*?name=\"test1\".*?) />#s;
	like $str, qr#type=\"hidden\"#s;
	like $str, qr#value=\"a1\"#s;

	($str)= $$catch=~m#<input (.*?name=\"test2\".*?) />#s;
	like $str, qr#type=\"text\"#s;
	like $str, qr#value=\"a2\"#s;

	($str)= $$catch=~m#<input (.*?name=\"test3\".*?) />#s;
	like $str, qr#type=\"password\"#s;
	like $str, qr#value=\"a3\"#s;

	($str)= $$catch=~m#<input (.*?name=\"test4\".*?) />#s;
	like $str, qr#type=\"checkbox\"#s;
	like $str, qr#value=\".+?\"#s;

	($str)= $$catch=~m#<input (.*?name=\"test5\".*?) />#s;
	like $str, qr#type=\"radio\"#s;
	like $str, qr#checked=\".+?\"#s;

	($str)= $$catch=~m#<textarea.+?name=\"test6\".*?>(.+?)</textarea>#s;
	like $str, qr/a6/;
}

__DATA__
---
filename: root/index.tt
value: |
  <html>
  <form method="POST" action="test">
  <input type="hidden" name="test1" />
  <input type="text" name="test2" />
  <input type="password" name="test3" />
  <input type="checkbox" name="test4" />
  <input type="radio" name="test5" value="foo" />
  <textarea name="test6"></textarea>
  </form>
  </html>
