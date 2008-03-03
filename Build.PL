use Module::Build;

my $builder = Module::Build->new(

  module_name       => 'Egg::Release',
  dist_version_from => 'lib/Egg/Release.pm',
  dist_abstract     => 'lib/Egg/Release.pm',
  dist_author       => 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>',
  license           => 'perl',

  requires => {

    'perl'                     => '5.8.1',
    'Carp'                     => '0',
    'CGI'                      => '3.33',
    'Class::Accessor'          => '0.31',
    'Class::C3'                => '0.19',
    'Class::Data::Inheritable' => '0.06',
    'Devel::StackTrace'        => '1.15',
    'Digest::MD5'              => '2.36',
    'Digest::SHA1'             => '2.11',
    'File::Path'               => '2.04',
    'File::Spec'               => '3.27',
    'File::Temp'               => '0.20',
    'File::Which'              => '0.05',
    'Getopt::Easy'             => '0.10',
    'HTML::Mason'              => '1.38',
    'HTML::Parser'             => '3.56',
    'HTML::Template'           => '2.90',
    'IO::Scalar'               => '2.11',
    'Jcode'                    => '2.06',
    'MIME::Base64'             => '3.07',
    'Module::Install'          => '0',
    'Tie::Hash::Indexed'       => '0.05',
    'Tie::RefHash'             => '1.38',
    'Time::HiRes'              => '0',
    'Time::Local'              => '1.18',
    'UNIVERSAL::require'       => '0.11',
    'URI'                      => '1.35',
    'YAML'                     => '0.66',
    'LWP'                      => '5.80',

    'FormValidator::Simple'    => '0.22',
    'HTML::FillInForm'         => '2.00',
    'HTML::Prototype'          => '1.48',
    'HTTP::BrowserDetect'      => '0.99',
    'ModPerl::VersionUtil'     => '0.03',
    'Module::Refresh'          => '0.13',
    'PersistentPerl'           => '2.21',

    'Test::More'          => '0',
    'Test::Pod'           => '0',
    'Test::Perl::Critic'  => '0',
    'Test::Pod::Coverage' => '0',
    },

  );

$builder->create_build_script();
