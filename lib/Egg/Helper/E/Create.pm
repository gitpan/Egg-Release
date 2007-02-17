package Egg::Helper::E::Create;
use strict;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: Create.pm 185 2007-02-17 07:18:18Z lushe $
#
use strict;
use warnings;
use base qw/Egg::Component/;

our $VERSION= '0.01';

sub new {
	my $self= shift->SUPER::new();
	my $g= $self->global;
	return $self->help_disp if ($g->{help} || ! $g->{any_name});
	my $part= $self->check_module_name
	  ($self->project_name, 'E', $g->{any_name});

	$self->setup_global_rc;
	$self->setup_document_code;
	$g->{created}= __PACKAGE__. " v$VERSION";
	$g->{lib_dir}= "$g->{project_root}/lib";
	$g->{engine_name}= join('-' , @$part);
	$g->{engine_distname}= join('::', @$part);
	$g->{engine_filename}= join('/' , @$part). '.pm';
	$g->{uc_project_name}= uc($self->project_name);

	-e "$g->{lib_dir}/$g->{engine_filename}"
	  and die "It already exists : $g->{lib_dir}/$g->{engine_filename}";

	$g->{number}= $self->get_testfile_new_number("$g->{project_root}/t")
	    || die 'The number of test file cannot be acquired.';

	$self->{add_info}= "";
	chdir($g->{project_root});
	eval {
		my @list= $self->parse_yaml(join '', <DATA>);
		$self->save_file($g, $_) for @list;
		$self->distclean_execute_make;
	  };
	chdir($g->{start_dir});

	if (my $err= $@) {
		unlink("$g->{lib_dir}/$g->{engine_filename}");
		die $err;
	} else {
		my $pname= $self->project_name;
		print <<END_OF_INFO;
... done.$self->{add_info}

Please edit 'lib/$g->{engine_filename}' and make a new engine.

#
# Is the environment variable defined with the control file.
#
   \$ENV{$pname\_ENGINE_CLASS}= '$g->{engine_distname}';

#
# Or, please define the configuration.
#

  __PACKAGE__->__egg_setup(
    ...
    engine_class=> '$g->{engine_distname}',
    );

END_OF_INFO
	}
}
sub output_manifest {
	my($self)= @_;
	$self->{add_info}= <<END_OF_INFO;

----------------------------------------------------------------
  !! MANIFEST was not able to be adjusted. !!
  !! Sorry to trouble you, but please edit MANIFEST later !!
----------------------------------------------------------------
END_OF_INFO
}
sub help_disp {
	my($self)= @_;
	my $pname= lc($self->project_name);
	print <<END_OF_HELP;
# usage: perl $pname\_helper.pl D:Make [NEW_ENGIN_NAME]

* The engine class is generated to 'lib/[PROJECT_ROOT]/E'.

END_OF_HELP
}

1;

=head1 NAME

Egg::Helper::E::Create - A helper who generates the skeleton of the engine for Egg.

=head1 SYNOPSIS

  cd /path/to/myproject/bin

  # Help is displayed.
  ./myproject_helper.pl E::Create -h
  
  # A new engine module is generated.
  ./myproject_helper.pl E::Create NewEngine

=head1 DESCRIPTION

This module generates the skeleton of the engine class for Egg.

A module necessary minimum because it functions as an engine of Egg is 
generated.

Please set the package name to MYPROJECT_ENGIN of engin_class of the 
configuration or the environment variable to build the made module into Egg.

=head1 SEE ALSO

L<Egg::Engine>,
L<Egg::Engine::V1>,
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
filename: lib/<# engine_filename #>
value: |
  package <# engine_distname #>;
  #
  # Copyright (C) <# headcopy #>, All Rights Reserved.
  # <# author #>
  #
  # <# revision #>
  #
  use strict;
  use warnings;
  use Class::C3;
  use UNIVERSAL::require;
  use base qw/Egg::Engine/;
  
  our $VERSION= '<# version #>';
  
  sub startup {
  	my($class, $e)= @_;
  	my $conf= $e->config;
  	my $ucName= uc($e->namespace);
  	my $G= $e->global;
  
  	my(@models, @views, %models, %views);
  	$G->{MODEL_CLASS}= \%models;
  	$G->{MODEL_LIST} = \@models;
  	$G->{VIEW_CLASS} = \%views;
  	$G->{VIEW_LIST}  = \@views;
  
  	# Setup of Model.
  	$conf->{mode} ||= {};
  	if (my $model= $conf->{MODEL}) {
  		for (@$model) {
  			my $pkg= "Egg::Model::$_->[0]";
  			$pkg->require or Egg::Error->throw($@);
  			push @models, $_->[0];
  			$models{$_->[0]}= $pkg;
  			$conf->{model}{$_->[0]}= $_->[1] || {};
  		}
  		for (@models) {
  			my $pkg= $models{$_};
  			$pkg->setup($e, $conf->{model}{$_});
  		}
  	}
  
  	# Setup of View.
  	$conf->{view} ||= {};
  	if (my $view= $conf->{VIEW}) {
  		for (@$view) {
  			my $pkg= "Egg::View::$_->[0]";
  			$pkg->require or Egg::Error->throw($@);
  			push @views, $_->[0];
  			$views{$_->[0]}= $pkg;
  			$conf->{view}{$_->[0]}= $_->[1] || {};
  		}
  		for (@views) {
  			my $pkg= $views{$_};
  			$pkg->setup($e, $conf->{view}{$_});
  		}
  	}
  
  	$class->SUPER::startup($e);
  }
  sub setup {
  	my($e)= @_;
  	$e->next::method;
  }
  sub run {
  	my($e)= @_;
  	Egg::Helper::Project::BlankPage->require;
  	$e->prepare_component;
  	$e->response->body( Egg::Helper::Project::BlankPage->out($e) );
  	$e->response->content_type($e->config->{content_type});
  	$e->finalize;
  	$e->output_content;
  	$e;
  }
  
  # Method for MODEL.
  sub model {
  	my $e= shift;
  	my $name= shift || $e->default_model || return 0;
  	$e->{model}{$name}
  	  ||= $e->model_class->{$name}->new($e, $e->config->{model}{$name});
  }
  sub models {
  	my($e)= @_;
  	$e->global->{MODEL_LIST};
  }
  sub model_class {
  	my($e)= @_;
  	$e->global->{MODEL_CLASS};
  }
  sub is_model {
  	my $e= shift;
  	my $name= shift || return 0;
  	$e->global->{MODEL_CLASS}{$name} || 0;
  }
  sub default_model {
  	my($e)= @_;
  	$e->global->{MODEL_LIST}->[0] || 0;
  }
  
  # Method for View.
  sub view {
  	my $e= shift;
  	my $name= shift || $e->default_view || return 0;
  	$e->{view}{$name}
  	  ||= $e->view_class->{$name}->new($e, $e->config->{view}{$name});
  }
  sub views {
  	my($e)= @_;
  	$e->global->{VIEW_LIST};
  }
  sub view_class {
  	my($e)= @_;
  	$e->global->{VIEW_CLASS};
  }
  sub is_view {
  	my $e= shift;
  	my $name= shift || return 0;
  	$e->global->{VIEW_CLASS}{$name} || 0;
  }
  sub default_view {
  	my($e)= @_;
  	$e->global->{VIEW_LIST}->[0] || 0;
  }
  
  1;
  
  __END__
  <# document #>
---
filename: t/<# number #>_<# engine_name #>.t
value: |
  
  use Test::More tests => 1;
  BEGIN { use_ok('<# engine_distname #>') };
  
---
filename: etc/<# examples #>/<# engine_name #>.setup
value: |
  # Please do the following setups and make '<# engine_distname #>' effective.
  
  #
  # Is the environment variable defined with the control file.
  #
     $ENV{<# uc_project_name #>_ENGINE_CLASS}= '<# engine_distname #>';
  
  #
  # Or, please define the configuration.
  #
  
    __PACKAGE__->__egg_setup(
      ...
      engine_class=> '<# engine_distname #>',
      );

