
use Test::More tests => 10;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new( prepare=> 1 );
my $e= $test->egg_pcomp_context;

ok my $view= $e->view;
isa_ok $view, 'Egg::View::Template';
ok my $ext= $e->config->{template_extention};
ok ! $view->template;
ok $e->action->[0]= 'index';
ok $view->template;
is $view->template, "index.$ext";
ok $e->action([qw{ hoge foo }]);
ok $view->template;
is $view->template, "hoge/foo.$ext";

