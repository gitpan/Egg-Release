
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;
use FindBin;

SKIP: {
eval{ require HTML::Prototype };
skip q{ 'HTML::Prototype' is not installed. } if $@;

my $v= Egg::Helper::VirtualTest->new( prepare=> {
  controller=> { egg_includes=> [qw/ Prototype /] },
  });

skip q{ Test with Windows is omitted. } if $v->is_win32;

$v->disable_allstd;

push @INC, "$FindBin::Bin/lib";
push @INC, "$FindBin::Bin/../lib";

ok my $e= $v->egg_context;
ok my $ptype= $e->prototype;

eval { require HTML::Prototype::Useful; };
if ($@) {
	isa_ok $ptype, 'HTML::Prototype';
} else {
	isa_ok $ptype, 'HTML::Prototype::Useful';
}

ok my $result= $v->helper_run('Plugin::Prototype');
ok my $static= $e->config->{dir}{static};

ok -e "$static/prototype.js";
ok -e "$static/controls.js";
ok -e "$static/dragdrop.js";

  };

