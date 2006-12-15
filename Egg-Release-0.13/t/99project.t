
use Test::More tests => 22;
use IO::Scalar;
use lib 't';
use Egg::Helper::Test;
my $et= new Egg::Helper::Test;

my $test= 'EggBuild';
my $tmp = $et->temp;
my $base= "$tmp/$test";
my $out;

push @INC, $et->current;
chdir($tmp);

#0
use_ok('Egg::Debug::SimpleBench');
use_ok('Egg::Helper::Script');
ok( Egg::Helper::Script->run( 'project', { project=> $test } ) );
ok( -d $base );
ok( -d "$base/bin" );

#5
ok( -f "$base/bin/triger.cgi" );
ok( -d "$base/lib" );
ok( -f "$base/lib/$test.pm" );
ok( -d "$base/lib/$test" );
ok( -f "$base/lib/$test/config.pm" );

#10
ok( -f "$base/lib/$test/D.pm" );
ok( -d "$base/lib/$test/D" );
ok( -f "$base/lib/$test/D/Root.pm" );
ok( -d "$base/htdocs" );
ok( -d "$base/htdocs/images" );

#15
ok( -d "$base/root" );
ok( -d "$base/comp" );
ok( -d "$base/tmp" );
ok( $out= &cgi_run($et) );
ok( $out=~m{X\-Egg\-[^\-]+\-ERROR}is ? 0: 1 );

#20
like( $out, qr{Content\-Type\:\s+text/html}is );
like( $out, qr{<h1>WELCOM\s+.+}is );

chdir($et->current);
pop @INC;

sub cgi_run {
	my($self)= @_;
	push @INC, $self->temp."/EggBuild/lib";
	EggBuild->require || return do { warn $@; 0 };
	package EggBuild;
	my $out;
	tie *STDOUT, 'IO::Scalar', \$out;
	my $cgi;
	eval {
		$cgi= EggBuild->new;
		$cgi->run;
	 };
	untie *STDOUT;
	return ($out || 0) unless (my $err= $@);
	print STDERR $err;
	return 0;
}
