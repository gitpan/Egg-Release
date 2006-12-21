use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name      => 'Egg::Release',
  license          => 'perl',
  dist_author      => 'Masatoshi Mizuno <mizuno@bomcity.com>',
  dist_version_from=> 'lib/Egg/Release.pm',
  requires => {
    'CGI' => 0,
    'CGI::Cookie' => 0,
    'Class::Accessor::Fast' => 0,
    'Class::Data::Inheritable' => 0,
    'Compress::Zlib' => 0,
    'DBI' => 0,
    'Data::Dump' => 0,
    'Error' => 0,
    'File::Path' => 0,
    'File::Temp' => 0,
    'File::Which' => 0,
    'FileHandle' => 0,
    'HTML::Entities' => 0,
    'HTML::Prototype' => 0,
    'HTML::Template' => 0,
    'HTML::Template::Ex' => 0,
    'HTTP::Date' => 0,
    'HTTP::Headers' => 0,
    'IO::Scalar' => 0,
    'Jcode' => 0,
    'NEXT' => 0,
    'Module::Install' => 0,
    'Test::More' => 0,
    'Test::Pod' => 0,
    'Time::HiRes' => 0,
    'UNIVERSAL::require' => 0,
    'URI' => 0,
    'YAML' => 0,
    },
  );

$builder->create_build_script();
