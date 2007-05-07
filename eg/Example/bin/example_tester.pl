#!/usr/local/bin/perl
use FindBin;
use lib "$FindBin::Bin/../lib";
use Egg::Helper;

Egg::Helper->run(
 'Project::Test',
  project_name => 'Example',
  project_root => './Example',
  );
