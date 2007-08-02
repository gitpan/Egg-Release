use inc::Module::Install;

name         'Egg-Release';
all_from     'lib/Egg/Release.pm';
version_from 'lib/Egg/Release.pm';
author       'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license      'perl';

# requires 'DBI'                   => 1.54,
# requires 'Ima::DBI'              => 0.34,
# requires 'FCGI'                  => 0.67,

requires 'ModPerl::VersionUtil'  => 0.03;
requires 'MIME::Base64'          => 3.07;
requires 'CGI'                   => 3.28;
requires 'Class::Accessor'       => 0.30;
requires 'Class::C3'             => 0.14;
requires 'Devel::StackTrace'     => 1.14;
requires 'Digest::SHA1'          => 2.11;
requires 'File::Spec'            => 3.24;
requires 'File::Temp'            => 0.18;
requires 'File::Which'           => 0.05;
requires 'FileHandle'            => 2.00;
requires 'FormValidator::Simple' => 0.22;
requires 'Getopt::Easy'          => 0.01;
requires 'HTML::FillInForm'      => 1.06;
requires 'HTML::Mason'           => 1.35;
requires 'HTML::Parser'          => 3.56;
requires 'HTML::Prototype'       => 1.48;
requires 'HTML::Template'        => 2.9;
requires 'Jcode'                 => 2.06;
requires 'ModPerl::VersionUtil'  => 0.03;
requires 'Tie::Hash::Indexed'    => 0.04;
requires 'Tie::RefHash'          => 1.35;
requires 'Time::HiRes'           => 0;
requires 'UNIVERSAL::require'    => 0.11;
requires 'URI'                   => 1.35;
requires 'WWW::Mechanize::CGI'   => 0.03;
requires 'YAML'                  => 0.62;

build_requires 'Test::Simple';
build_requires 'Test::Pod';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
