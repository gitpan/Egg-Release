use inc::Module::Install;

name         'Example';
all_from     'lib/Example.pm';
version_from 'lib/Example.pm';
author       'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>';
license      'perl';

requires 'Egg::Release' => 2.00;

build_requires 'Test::More';
build_requires 'Test::Pod';
# build_requires 'Test::Perl::Critic';
# build_requires 'Test::Pod::Coverage';

use_test_base;
auto_include;
WriteAll;
