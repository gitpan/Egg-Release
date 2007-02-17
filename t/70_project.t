
use Test::More qw/no_plan/; #tests => 22;
use UNIVERSAL::require;
use Egg::Helper;

my $t= Egg::Helper->run('O:Test');
my $g= $t->global;
$t->create_project_root;
my $out  = $ENV{EGG_OUT_PATH}= $g->{out_path};
my $pname= $t->project_name;
my $proot= "$out/$pname";
my $lname= lc($pname);

my @libs = (
  "$g->{start_dir}/../lib",
  "$g->{start_dir}/lib",
  "$out/$pname/lib",
  );
$g->{debug_libs}= "\nuse lib qw( ". join(' ', @libs). " );";

splice @INC, 0, 0, @libs;

ok( Egg::Helper->run( "Project:$pname" ) );
ok( -e "$proot" && -d _ );
ok( -e "$proot/bin" && -d _ );
ok( -e "$proot/bin/trigger.cgi" && -f _ );
ok( -e "$proot/bin/$lname\_helper.pl" && -f _ );
ok( -e "$proot/lib" && -d _ );
ok( -e "$proot/lib/$pname.pm" && -f _ );
ok( -e "$proot/lib/$pname" && -d _ );
ok( -e "$proot/lib/$pname/config.pm" && -f _ );
ok( -e "$proot/lib/$pname/D.pm" && -f _ );
ok( -e "$proot/htdocs" && -d _ );
ok( -e "$proot/htdocs/images" && -d _ );
ok( -e "$proot/root"  && -d _ );
ok( -e "$proot/comp"  && -d _ );
ok( -e "$proot/tmp"   && -d _ );
ok( -e "$proot/cache" && -d _ );

my $catch= $t->catch_stdout( sub {
	$pname->require or die $@;
	$pname->handler;
  });

if ($catch) {
	like $$catch, qr#Content\-Length\:\s+\d+#s;
	like $$catch, qr#Content\-Type\:\s+text/html#s;
	like $$catch, qr#X\-Egg\-$pname\:\s+[\d\.]+#s;
	like $$catch, qr#<title>$pname\-[\d\.]+.*?</title>#s;
	like $$catch, qr#<h1>.+?BLANK\s+PAGE.+?</h1>#s;
	like $$catch, qr#<h2>.+?$pname\-[\d\.]+.*?</h2>#s;
}
