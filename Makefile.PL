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
requires 'File::Path';
requires 'File::Which';
requires 'FileHandle';
requires 'HTML::Entities';
requires 'HTML::Prototype';
requires 'HTML::Template';
requires 'HTTP::Date';
requires 'HTTP::Headers';
requires 'Jcode';
requires 'NEXT';
requires 'Time::HiRes';
requires 'UNIVERSAL::require';
requires 'URI';
requires 'YAML';
requires 'Test::More';
requires 'File::Temp';
requires 'IO::Scalar';

build_requires 'Test::Pod';

auto_install;
WriteAll;
EXE_FILES
