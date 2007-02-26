use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(

  module_name       => 'Egg::Release',
  dist_version_from => 'lib/Egg/Release.pm',
  dist_author       => 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>',
  license           => 'perl',

  requires => {
    'CGI' => 0,
    'Class::Accessor' => 0,
    'Class::Data::Inheritable' => 0,
    'Class::C3' => 0,
    'Compress::Zlib' => 0,
    'Devel::StackTrace' => 0,
    'DBI' => 0,
    'Data::Dump'  => 0,
    'File::Path'  => 0,
    'File::Temp'  => 0,
    'File::Which' => 0,
    'FileHandle'  => 0,
    'Getopt::Easy'=> 0,
    'HTML::Entities' => 0,
    'HTML::Prototype' => 0,
    'HTML::Mason' => 0,
    'HTML::Template' => 0,
    'HTML::FillInForm'=> 0,
    'HTTP::Date' => 0,
    'HTTP::Headers' => 0,
    'IO::Scalar' => 0,
    'Jcode' => 0,
    'ModPerl::VersionUtil' => 0,
    'Module::Install' => 0,
    'Test::More' => 0,
    'Test::Pod' => 0,
    'Time::HiRes' => 0,
    'UNIVERSAL::require' => 0,
    'Tie::RefHash' => 0,
    'URI' => 0,
    'YAML' => 0,
    },

  );

$builder->create_build_script();
