
use Test::More tests => 28;

BEGIN {

use_ok('Egg');
use_ok('Egg::Base');
use_ok('Egg::Const');
use_ok('Egg::Release');
use_ok('Egg::Engine::V1');
use_ok('Egg::Request');
use_ok('Egg::Response');
use_ok('Egg::Dispatch::Runmode');
use_ok('Egg::Model::DBI');
use_ok('Egg::View::Mason');
use_ok('Egg::Helper');
use_ok('Egg::Helper::M::DBI');
use_ok('Egg::Helper::V::Mason');
use_ok('Egg::Helper::E::Create');
use_ok('Egg::Helper::D::Make');
use_ok('Egg::Helper::P::Prototype');
use_ok('Egg::Helper::P::YAML');
use_ok('Egg::Helper::P::Charset');
use_ok('Egg::Helper::Project::Build');
use_ok('Egg::Helper::Project::BlankPage');
use_ok('Egg::Helper::R::FastCGI');
use_ok('Egg::Helper::O::MakeMaker');
use_ok('Egg::Helper::O::Test');
use_ok('Egg::Plugin::ErrorDocument');
use_ok('Egg::Plugin::Filter::EUC_JP');
use_ok('Egg::Plugin::Pod::HTML');
use_ok('Egg::Plugin::Dispatch::AnyCall');
use_ok('Egg::Plugin::Redirect::Page');

};
