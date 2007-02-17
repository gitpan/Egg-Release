use 5.008006;
use inc::Module::Install;

name         'Egg-Release';
all_from     'lib/Egg/Release.pm';
version_from 'lib/Egg/Release.pm';
license      'perl';

requires 'CGI';
requires 'CGI::Cookie';
requires 'Class::Accessor::Fast';
requires 'Class::Data::Inheritable';
requires 'Class::C3';
requires 'Devel::StackTrace';
requires 'DBI';
requires 'Data::Dump';
requires 'File::Copy';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Temp';
requires 'File::Which';
requires 'FileHandle';
requires 'Getopt::Easy';
requires 'HTML::Entities';
requires 'HTML::Prototype';
requires 'HTML::Mason';
requires 'HTML::Template';
requires 'HTTP::Date';
requires 'HTTP::Headers';
requires 'HTML::FillInForm';
requires 'IO::Scalar';
requires 'Jcode';
requires 'ModPerl::VersionUtil';
requires 'Module::Install';
requires 'Test::More';
requires 'Time::HiRes';
requires 'UNIVERSAL::require';
requires 'Tie::RefHash';
requires 'URI';
requires 'YAML';

build_requires 'Test::Pod';

auto_install;
WriteAll;
EXE_FILES
