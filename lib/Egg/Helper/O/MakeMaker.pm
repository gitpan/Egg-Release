package Egg::Helper::O::MakeMaker;
#
# Copyright (C) 2007 Bee Flag, Corp, All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: MakeMaker.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use warnings;
use UNIVERSAL::require;
use base qw/Egg::Component/;

our $VERSION = '0.01';

sub new {
	my $self= shift->SUPER::new();
	my $G= $self->global;
	return $self->help_disp if (! $G->{help} && ! $G->{any_name});
	my $part= $self->check_module_name($G->{any_name});

	$self->setup_global_rc;
	$G->{created}= __PACKAGE__. " v$VERSION";
	$G->{module_name}= join '-', @$part;
	$G->{target_path}= "$G->{out_path}/$G->{module_name}";
	$G->{module_filename}= join('/' , @$part). '.pm';
	$G->{module_distname}= join('::', @$part);
	$G->{module_version} = $G->{version} || '0.01';
	$self->setup_document_code;

	$self->chdir($G->{target_path}, 1);
	eval{
		{
			my @list= $self->parse_yaml(join '', <DATA>);
			$self->save_file($G, $_) for @list;
		  };
		$self->execute_make;
	  };
	$self->chdir($G->{start_dir});

	if (my $err= $@) {
		$self->remove_dir($G->{target_path});
		die $err;
	} else {
		print "\n... completed.\n";
	}
}
sub output_manifest {
	my($self)= @_;

	my $manifest= <<MANIFEST_OF_END;
Build.PL
Changes
MANIFEST			This list of files
META.yml
Makefile.PL
README
lib/<# module_filename #>
t/00_use.t
t/89_pod.t
t/99_perlcritic.t
MANIFEST_OF_END

	$self->save_file
	  ( $self->global, { filename=> 'MANIFEST', value=> $manifest } );
}
sub help_disp {
	print <<END_OF_HELP;
# usage: egg_makemaker.pl [NEW_MODULE_NAME] [-h]

#
# * Generation of script.
#
# perl -MEgg::Helper::O::MakeMaker \\
#  -e "Egg::Helper::O::MakeMaker->out" > /path/to/bin/egg_makemaker.pl
#
# chmod 755 /path/to/bin/egg_makemaker.pl
#
END_OF_HELP
	exit;
}
sub out {
	Egg::Helper->require;
	my $perl_path= Egg::Helper->perl_path;
	print <<END_OF_SCRIPT;
#!$perl_path
#
# This script generates the fixed form module for Perl.
#
use Egg::Helper;
Egg::Helper->run('O::MakeMaker');
END_OF_SCRIPT
}

1;

=head1 NAME

Egg::Helper::O::MakeMaker - The skeleton of the module for the pearl is generated.

=head1 SYNOPSIS

  perl -MEgg::Helper::O::MakeMaker \
  -e "Egg::Helper::O::MakeMaker->out" > /path/to/egg_makemaker.pl
  
  chmod 755 /path/to/egg_makemaker.pl
  
  # Help is displayed.
  /path/to/egg_makemaker.pl -h
  
  # The skeleton of the module is generated.
  /path/to/egg_makemaker.pl Egg-Plugin-MyPlugin

=head1 DESCRIPTION

This module generates the skeleton of the module for perl.

-o The output destination can be specified by the option.
The output destination of default is a current directory.

=head1 SEE ALSO

L<Egg::Helper>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
---
filename: Makefile.PL
value: |
  use inc::Module::Install;
  name '<# module_name #>';
  author '<# author #>';
  all_from 'lib/<# module_filename #>';
  version_from 'lib/<# module_filename #>';
  
  build_requires 'Test::More';
  build_requires 'Test::Pod';
  
  use_test_base;
  auto_include;
  WriteAll;
---
filename: Build.PL
filetype: module
value: |
  use Module::Build;
  
  my $builder = Module::Build->new(
    module_name => '<# module_distname #>',
    license => '<# license #>',
    dist_author => '<# author #>',
    dist_version_from=> 'lib/<# module_filename #>',
    requires => {
      'Test::More' => 0,
      'Test::Pod'  => 0,
      },
    );
  
  $builder->create_build_script();
---
filename: lib/<# module_filename #>
filetype: module
value: |
  package <# module_distname #>;
  #
  # Copyright (C) <# year #> <# headcopy #>, All Rights Reserved.
  # <# author #>
  #
  # <# revision #>
  #
  use strict;
  use warnings;
  
  our $VERSION = '<# module_version #>';
  
  # Preloaded methods go here.
  
  1;
  
  __END__
  <# document #>
---
filename: t/00_use.t
value: |
  # Before `make install' is performed this script should be runnable with
  # `make test'. After `make install' it should work as `perl test.t'
  
  #########################
  
  # change 'tests => 1' to 'tests => last_test_to_print';
  
  use Test::More tests => 1;
  BEGIN { use_ok('<# module_distname #>') };
  
  #########################
  
  # Insert your test code below, the Test::More module is use()ed here so read
  # its man page ( perldoc Test::More ) for help writing this test script.
---
filename: t/89_pod.t
value: |
  use Test::More;
  eval "use Test::Pod 1.00";
  plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
  all_pod_files_ok();
---
filename: t/99_perlcritic.t
value: |
  use strict;
  use Test::More;
  eval q{ use Test::Perl::Critic };
  plan skip_all => "Test::Perl::Critic is not installed." if $@;
  all_critic_ok("lib");
---
filename: Changes
value: |
  Revision history for Perl extension <# distname #>.
  
  <# module_version #>  <# gmtime_string #>
  	- original version; created by <# created #>
  	   with module name <# module_distname #>
---
filename: README
value: |
  <# module_distname #>.
  =================================================
  
  The README is used to introduce the module and provide instructions on
  how to install the module, any machine dependencies it may have (for
  example C compilers and installed libraries) and any other information
  that should be provided before the module is installed.
  
  A README file is required for CPAN modules since CPAN extracts the
  README file from a module distribution so that people browsing the
  archive can use it get an idea of the modules uses. It is usually a
  good idea to provide version information here so that people can
  decide whether fixes for the module are worth downloading.
  
  INSTALLATION
  
  To install this module type the following:
  
     perl Makefile.PL
     make
     make test
     make install
  
     or
  
     perl Build.PL
     ./Build
     ./Build test
     ./Build install
  
  DEPENDENCIES
  
  This module requires these other modules and libraries:
  
    blah blah blah
  
  AUTHOR
  
  <# author #>
  
  COPYRIGHT AND LICENCE
  
  Put the correct copyright and licence information here.
  
  Copyright (C) <# year #> by <# copyright #>, All Rights Reserved.
  
  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.8.6 or,
  at your option, any later version of Perl 5 you may have available.
---
filename: MANIFEST.SKIP
value: |
  \bRCS\b
  \bCVS\b
  ^inc/
  ^blib/
  ^_build/
  ^MANIFEST\.
  ^Makefile$
  ^pm_to_blib
  ^MakeMaker-\d
  ^t/9\d+_.*\.t
  Build$
  \.cvsignore
  \.?svn*
  ^\%
  (~|\-|\.(old|save|back|gz))$
