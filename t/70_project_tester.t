
use Test::More qw/no_plan/;
use Egg::Helper::VirtualTest;

my $test= Egg::Helper::VirtualTest->new( prepare=> {} );

SKIP: {
skip q{ WWW::Mechanize::CGI is not installed. } unless $test->mech_ok;

eval{ require Egg::Helper::Project::Test };
$@ and die $@;
skip qq{ WWW::Mechanize is not installed. } if $@;

$test->disable_allstd;

chmod 0755, $test->project_root.'/bin/trigger.cgi';

ok my $mech= Egg::Helper->run('Project::Test');

  };

