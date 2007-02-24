
use Test::More tests => 20;

BEGIN {

#0
use_ok('Egg');
use_ok('Egg::Const');
use_ok('Egg::Release');
use_ok('Egg::Engine::V1');
use_ok('Egg::Request');

#5
use_ok('Egg::Response');
use_ok('Egg::Dispatch::Runmode');
use_ok('Egg::Model::DBI');
use_ok('Egg::View::Mason');
use_ok('Egg::Helper');

#10
use_ok('Egg::Helper::M::DBI');
use_ok('Egg::Helper::V::Mason');
use_ok('Egg::Helper::E::Create');
use_ok('Egg::Helper::D::Make');
use_ok('Egg::Helper::P::Prototype');

#15
use_ok('Egg::Helper::P::YAML');
use_ok('Egg::Helper::Project::Build');
use_ok('Egg::Helper::Project::BlankPage');
use_ok('Egg::Helper::O::MakeMaker');
use_ok('Egg::Helper::O::Test');

};
