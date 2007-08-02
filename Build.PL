use Module::Build;

my $builder = Module::Build->new(

  module_name       => 'Egg::Release',
  dist_version_from => 'lib/Egg/Release.pm',
  dist_author       => 'Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>',
  license           => 'perl',

  requires => {
#    'DBI'                   => 1.54,
#    'Ima::DBI'              => 0.34,
#    'FCGI'                  => 0.67,

    'ModPerl::VersionUtil'  => 0.03,
    'MIME::Base64'          => 3.07,
    'CGI'                   => 3.28,
    'Class::Accessor'       => 0.30,
    'Class::C3'             => 0.14,
    'Devel::StackTrace'     => 1.14,
    'Digest::SHA1'          => 2.11,
    'File::Spec'            => 3.24,
    'File::Temp'            => 0.18,
    'File::Which'           => 0.05,
    'FileHandle'            => 2.00,
    'FormValidator::Simple' => 0.22,
    'Getopt::Easy'          => 0.01,
    'HTML::FillInForm'      => 1.06,
    'HTML::Mason'           => 1.35,
    'HTML::Parser'          => 3.56,
    'HTML::Prototype'       => 1.48,
    'HTML::Template'        => 2.9,
    'Jcode'                 => 2.06,
    'Tie::Hash::Indexed'    => 0.04,
    'Tie::RefHash'          => 1.35,
    'Time::HiRes'           => 0,
    'UNIVERSAL::require'    => 0.11,
    'URI'                   => 1.35,
    'WWW::Mechanize::CGI'   => 0.03,
    'YAML'                  => 0.62,

    'Test::Simple'          => 0,
    'Test::Pod'             => 0,
    'Test::Perl::Critic'    => 0,
    'Test::Pod::Coverage'   => 0,
    },

  );

$builder->create_build_script();
