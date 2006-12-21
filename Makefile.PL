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
requires 'DBI';
requires 'Data::Dump';
requires 'Error';
requires 'File::Copy';
requires 'File::Path';
requires 'File::Spec';
requires 'File::Temp';
requires 'File::Which';
requires 'FileHandle';
requires 'HTML::Entities';
requires 'HTML::Prototype';
requires 'HTML::Template';
requires 'HTTP::Date';
requires 'HTTP::Headers';
requires 'IO::Scalar';
requires 'Jcode';
requires 'NEXT';
requires 'Module::Install';
requires 'Test::More';
requires 'Time::HiRes';
requires 'UNIVERSAL::require';
requires 'URI';
requires 'YAML';

build_requires 'Test::Pod';

auto_install;
WriteAll;
EXE_FILES
