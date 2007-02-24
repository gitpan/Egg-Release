package Egg::Helper::O::Test::Prepare;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Prepare.pm 236 2007-02-24 10:26:28Z lushe $
#
use strict;
use warnings;
use Data::Dumper;

our $VERSION= '0.02';

sub prepare {
	my $self = shift;
	my $args = $_[0] ? ($_[1] ? {@_}: $_[0]): {};
	my $pname= $args->{project_name} || 0;
	$self->create_project_root($pname) unless $self->project_root;
	my $g= $self->global;
	$g->{lc_name}= lc($self->project_name);

	$g->{extend_lib}= $args->{extend_lib} || "";

	$self->prepare_include_path
	  ($args->{include_path}) if $args->{include_path};
	$self->prepare_config
	  ($args->{config}) if $args->{config};
	$self->__setup_default_config($g, $args);

	$self->prepare_controller($args->{controller}) if $args->{controller};
	$g->{egg_options}= ' qw/'. join(' ', @{$self->{egg_options}}). '/'
	  if ($self->{egg_options} && @{$self->{egg_options}});

	$self->prepare_dispatch($args->{dispatch})  if $args->{dispatch};
	$g->{dispatch_run_modes} ||= <<END_OF_CODE;
_default=> sub {
	my(\$dispatch, \$e)= \@_;
	require Egg::Helper::Project::BlankPage;
	\$e->response->body( Egg::Helper::Project::BlankPage->out(\$e) );
  },
END_OF_CODE

	for my $key (qw/default_mode mode_param/) {
		my $name= "despatch_$key";
		my $text= $g->{$name} || next;
		$g->{$name}= "__PACKAGE__->$key\('$text');"
	}
	for my $key (qw/dispatch_run_modes project_config/) {
		my $text= $g->{$key} || next;
		$g->{$key}= sub {
			my($proto, $param, $fname)= @_;
			$proto->conv($param, \$text, $fname);
		  };
	}
	$self->setup_global_rc;
	$self->setup_document_code;

	$self->chdir($g->{project_root}, 1);
	eval{
		{
			my @list= $self->parse_yaml( join '', <DATA> );
			$self->save_file($g, $_) for @list;
		  };
		if (my $files= $args->{create_files}) {
			$self->save_file($g, $_) for @$files;
		}
		$self->create_dir("$g->{project_root}/$_")
		  for qw(root cache tmp tmp/uploads comp htdocs t);
	  };
	$self->chdir($g->{start_dir});

	if (my $err= $@) {
		$self->remove_dir($g->{project_root});
		die $err;
	}
	unshift @INC, "$g->{project_root}/lib";
	$self;
}
sub __setup_default_config {
	my($self, $g, $args)= @_;
	my $cf= $g->{project_config} ||= {};
	$cf->{title} ||= '<# project_name #>';
	$cf->{root}  ||= '<# project_root #>';
	$cf->{static_root} ||= 'htdocs';
	$cf->{template_path}
	  ||= ['<# project_root #>/root', '<# project_root #>/comp'];
	$cf->{request} ||= {};
	$cf->{request}{POST_MAX} ||= 10240;
	$cf->{request}{DISABLE_UPLOADS}= 0
	  unless defined($cf->{request}{DISABLE_UPLOADS});
	$cf->{request}{TEMP_DIR} ||= '<# project_root #>/tmp/uploads';
	$cf->{VIEW} ||= do {
		if ($args->{mason_ok}) {
			[ [ Mason => {
				  comp_root=> [
				    [ main   => '<# project_root #>/root' ],
				    [ private=> '<# project_root #>/comp' ],
				    ],
				  data_dir=> '<# project_root #>/tmp',
				  },
			  ] ];
		} else {
			[ [ Template=> {
				  path=> [
				    '<# project_root #>/root',
				    '<# project_root #>/comp',
				    ],
				  global_vars=> 1,
				  die_on_bad_params=> 1,
				  },
			  ] ];
		}
	  };
	my $temp= Data::Dumper::Dumper($cf);
	$temp=~s{^[^\{]+\{\s+} []s;
	$temp=~s{\s+\}\;\s+$} [\n]s;
	$g->{project_config} = $temp;
	$g->{project_version}= '0.01';
}
sub prepare_include_path {
	my $g  = shift->global;
	my $inc= $_[0] ? (ref($_[0]) ? $_[0]: [@_]): die 'I want include path.';
	$g->{include_path}= 'use lib qw('. join(' ', @$inc). ');';
}
sub prepare_controller {
	my $self= shift;
	my $args= $_[0] ? (ref($_[0]) ? $_[0]: {@_}): die 'I want args.';
	my $g= $self->global;
	$g->{project_version}= $args->{version} || '0.01';
	$g->{extend_codes_first}=
	  $args->{extend_codes_first} if $args->{extend_codes_first};
	$g->{extend_codes}= $args->{extend_codes} if $args->{extend_codes};
	$self->prepare_egg($args->{egg}) if $args->{egg};
}
sub prepare_egg {
	my $self= shift;
	if (@_) {
		if (my $array= $_[0]
		  ? (ref($_[0]) eq 'ARRAY' ? $_[0]: [@_]): 0) {
			if ($self->{egg_options}) {
				splice @{$self->{egg_options}}, 0, 0, @$array;
			} else {
				$self->{egg_options}= $array;
			}
		} else {
			$self->{egg_options}= [];
		}
	}
	$self->{egg_options} ||= [];
}
sub prepare_dispatch {
	my $self= shift;
	my $args= $_[0] ? (ref($_[0]) ? $_[0]: {@_}): die 'I want args.';
	my $g= $self->global;
	$g->{dispatch_run_modes}= $args->{run_modes} if $args->{run_modes};
	$g->{dispatch_extend_codes_first}=
	  $args->{extend_codes_first} if $args->{extend_codes_first};
	$g->{dispatch_extend_codes}= $args->{extend_codes} if $args->{extend_codes};
	$g->{dispatch_default_mode}= $args->{default_mode} if $args->{default_mode};
	$g->{dispatch_mode_param}= $args->{mode_param} if $args->{mode_param};
}
sub prepare_config {
	my $g= shift->global;
	$g->{project_config}= shift || die 'I want config text.';
	ref($g->{project_config}) eq 'HASH' || die 'is not good in the reference.';
}

1;

=head1 NAME

Egg::Helper::O::Test::Prepare - A virtual project for the test is constructed.

=head1 SYNOPSIS

  use Egg::Helper;
  
  my $test= Egg::Helper->run('O::Test');
  
  my $run_modes= <<END_OF_RUNMODES;
   _default=> sub {},
   foo=> {
     qr/a(\d+)/=> sub { .... },
     { hoge=> 'POST' }=> \\\&MYPROJECT::D::Foo::hoge,
     },
  END_OF_RUNMODES
  
  $test->prepare(
    project_name => 'MyProject',
    config=> {
      title=> 'test project.',
      },
    include_path=> [qw( /path/perl-lib /path/lib )],
    controller => {
      egg=> [qw/-Debug PluginName/],
      },
    dispatch=> {
      extend_codes_first=> "use MYPROJECT::D::Foo;\n",
      run_modes=> $run_modes,
      },
    );

=head1 DESCRIPTION

The virtual project file is generated and this module is constructed.

The main method is 'prepare', and other 'prepare_*' is called according to the
option to usually pass to 'prepare'.

=head1 METHODS

The methods other than 'prepare' need not be individually called usually.

=head2 prepare ([OPTION])

The work directory is temporarily made, the virtual project file is generated
there, and the project environment for the test is constructed.

The following files are generated in default.

  /tmp/... /EggVirtual/lib/EggVirtual.pm
  /tmp/... /EggVirtual/lib/EggVirtual/config.pm
  /tmp/... /EggVirtual/lib/EggVirtual/D.pm
  /tmp/... /EggVirtual/bin/trigger.cgi
  /tmp/... /EggVirtual/bin/eggvirtual_helper.pl
  /tmp/... /EggVirtual/Makefile.PL
  /tmp/... /EggVirtual/Build.PL
  /tmp/... /EggVirtual/htdocs
  /tmp/... /EggVirtual/root
  /tmp/... /EggVirtual/comp
  /tmp/... /EggVirtual/tmp/uploads
  /tmp/... /EggVirtual/cache

It is possible to customize it by passing the option composed of HASH.

List of option.

=over 4

=item * project_name

The project name is specified.

Default becomes a name obtained with $test->project_name.

=item * include_path

The include passing can be set by the ARRAY reference.

* It uses it to specify the include passing besides the project root.

=item * config

The configuration can be set by the HASH reference.

* Necessary minimum configuration is set by default.

=item * mason_ok

Mason is used to set VIEW. Default is Template.

If VIEW is set to config, this option doesn't have the meaning.

* However, it stays in both cases in a rudimentary setting.

=item * controller

The setting to customize the controller file can be set by the HASH reference.

=over 4

=item * egg

The module option to pass to Egg is set by the ARRAY reference.
Please set the debugging flag and the plugin, etc.

  controller=> {
    egg=> [qw{ -Debug Filter Encode }],
    },

=item * version

It is a version of the controller file. Default is '0.01'.

=item * extend_codes_first

The script code of the first stage of the controller file is given by the text.
I think that it becomes a code for the module to want to read and the module to
want to succeed to usually.

  my $ctl_code_first= <<END_OF_CODE;
  use Unicode::Japanise;
  use base qw/MYPROJECT::BASE/;
  END_OF_CODE
  
  controller=> {
    extend_codes_first=> $ctl_code_first,
    },

=item * extend_codes

The script code in the latter half of the controller file is given by the text.

  my $ctl_code= <<END_OF_CODE;
  sub create_encode {
  	my(\$e)= \@_;
  	Unicode::Japanise->new;
  }
  END_OF_CODE
  
  controller=> {
    extend_codes=> $ctl_code,
    },

=back

=item * dispatch

The setting to customize dispatch can be set by the HASH reference.

=over 4

=item * run_modes

The setting of __PACKAGE__->run_modes can be set in the text.
Please note that it is not HASH.
Moreover, please describe the part in parentheses of __PACKAGE__->run_modes(  );.

  my $run_modes= <<END_OF_RUNMODE;
    _default=> sub {},
    foge=> {
      { foo=> 'GET'  }=> \\\&foo,
      { boo=> 'POST' }=> \\\&MYPROJECT::D::CUSTOM::boo,
      },
  END_OF_RUNMODE
  
  dispatch=> {
    run_modes=> $run_modes,
    },

=item * default_mode

The value given to __PACKAGE__->default_mode can be set. 

  dispatch=> {
    default_mode=> '_index',
    },

=item * mode_param

The value given to __PACKAGE__->mode_param can be set. 

  dispatch=> {
    mode_param=> 'mode',
    },

=item * extend_codes_first

The script code of the first stage of dispatch is given by the text.

  my $dispat_code_first= <<END_OF_CODE;
  use MYPROJECT::D::CUSTOM;
  END_OF_CODE
  
  dispatch=> {
    extend_codes_first=> $dispat_code_first,
    },

=item * extend_codes

The script code in the latter half of dispatch is given by the text.

  my $dispat_code= <<END_OF_CODE;
  sub foo {
  	my(\$dispat, \$e)= \@_;
  	\$e->response->body('is foo page.');
  }
  END_OF_CODE

=back

=item * create_files

To make a file besides the file made from default, data is given by the ARRAY
reference.
Please set each value of ARRAY by the form given to $test->save_file.

After it moves to project_root, the file is made.
Therefore, filename can be specified by the relative path.
Moreover, $test->conv is substituted.

  my $file_value= <<END_OF_VALUE;
  package <# project_name #>::D::CUSTOM;
  use strict;
  sub boo {
  	my(\$dispat, \$e)= \@_;
  	\$e->response->body('is boo.');
  }
  END_OF_VALUE
  
  create_files=> [
    {
      filename=> 'lib/<# project_name #>/D/CUSTOM.pm',
      value=> $file_value,
      },
    ],

=back

=head2 prepare_controller

It sets it concerning the controller.

=head2 prepare_include_path

The ink route passing is set.

=head2 prepare_egg

The module option of Egg is set.

=head2 prepare_dispatch

It sets it concerning dispatch.

=head2 prepare_config

It sets it concerning the configuration.

=head1 SEE ALSO

L<Egg::Helper::O::Test>,
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
filename: lib/<# project_name #>.pm
value: |
  package <# project_name #>;
  use strict;
  <# include_path #>
  use Egg<# egg_options #>;
  <# extend_codes_first #>
  use <# project_name #>::config;
  our $VERSION= '<# project_version #>';
  my $config= <# project_name #>::config->out;
  __PACKAGE__->__egg_setup($config);
  <# extend_codes #>
---
filename: Makefile.PL
value: |
  use inc::Module::Install;
  name '<# project #>';
  all_from 'lib/<# project #>.pm';
  version_from 'lib/<# project #>.pm';
  requires 'Egg::Release';
  build_requires 'Test::More';
  build_requires 'Test::Pod';
  use_test_base;
  auto_include;
  WriteAll;
---
filename: Build.PL
value: |
  use Module::Build;
  my $builder = Module::Build->new(
    module_name => '<# project #>',
    license => '<# license #>',
    dist_author => '<# author #>',
    dist_version_from=> 'lib/<# project #>.pm',
    requires => {
      'Egg::Release' => 1.00,
      'Test::More'   => 0,
      'Test::Pod'    => 0,
      },
    );
  $builder->create_build_script();
---
filename: bin/trigger.cgi
permission: 0755
value: |
  #!<# perl_path #>
  package <# project #>::trigger;
  use lib qw( <# project_root #>/lib <# extend_lib #>);
  use <# project #>;
  <# project #>->handler(@_);
---
filename: bin/<# lc_name #>_helper.pl
permission: 0755
value: |
  #!<# perl_path #>
  use lib qw( <# project_root #>/lib <# extend_lib #>);
  use Egg::Helper;
  Egg::Helper->run(
  shift(@ARGV),
  '<# project #>',
  { project_root=> '<# project_root #>' },
  );
---
filename: lib/<# project #>/D.pm
value: |
  package <# project #>::D;
  use strict;
  use warnings;
  use Egg::Const;
  <# dispatch_extend_codes_first #>
  our $VERSION= '0.01';
  __PACKAGE__->run_modes(
  <# dispatch_run_modes #>
  );
  <# dispatch_default_mode #>
  <# dispatch_mode_param #>
  <# dispatch_extend_codes #>
  1;
---
filename: lib/<# project #>/config.pm
value: |
  package <# project #>::config;
  use strict;
  use warnings;
  my %config= (
  <# project_config #>
  );
  sub out { \%config }
  1;
