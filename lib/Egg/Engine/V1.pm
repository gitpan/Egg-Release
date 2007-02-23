package Egg::Engine::V1;
#
# Copyright 2007 Bee Flag, Corp. All Rights Reserved.
# Masatoshi Mizuno E<lt>mizunoE<64>bomcity.comE<gt>
#
# $Id: V1.pm 230 2007-02-23 06:50:37Z lushe $
#
use strict;
use UNIVERSAL::require;
use base qw/Egg::Engine/;

our $VERSION= '0.02';

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

	for my $type
	  (['model', \@models, \%models], ['view',  \@views,  \%views ]) {
		my $ucName= uc($type->[0]);

		no strict 'refs';  ## no critic
		*{__PACKAGE__."::is_$type->[0]"}= sub {
			my $egg = shift;
			my $name= shift || return 0;
			$egg->global->{"$ucName\_CLASS"}{$name} || 0;
		  };
		my $default= "default_$type->[0]";
		*{__PACKAGE__."::$default"}= sub {
			my $egg= shift;
			$egg->{$default}= $egg->__check_comps($type->[0], @_) if $_[0];
			$egg->{$default} ||= $egg->global->{"$ucName\_LIST"}->[0] || 0;
		  };
		*{__PACKAGE__."::$type->[0]s"}=
		  sub { $_[0]->global->{"$ucName\_LIST"} };
		*{__PACKAGE__."::$type->[0]_class"}=
		  sub { $_[0]->global->{"$ucName\_CLASS"} };
		$conf->{$type->[0]}= {};
		if (my $list= $conf->{$ucName}) {
			&__include_comps($e, @$_, @$type) for @$list;
		}
		for my $name (@{$type->[1]}) {
			my $pkg= $type->[2]{$name} || next;
			$pkg->setup($e, $conf->{$type->[0]}{$name});
		}
	}

	$class->SUPER::startup($e);
}
sub setup {
	my($e)= @_;
	no strict 'refs';  ## no critic
	*{__PACKAGE__.'::start_engine'}= $e->debug ? sub {
		my($egg)= @_;
		Egg::Debug::SimpleBench->require or Egg::Error->throw($@);
		my $bench= Egg::Debug::SimpleBench->new;
		$bench->settime;
		$egg->prepare_component;
		$egg->debug_report_output;
		$egg->step1; $bench->stock('step1:');
		$egg->step2; $bench->stock('step2:');
		$egg->step3; $bench->stock('step3:');
		$bench->out;
	  }: sub {
		my($egg)= @_;
		$egg->prepare_component;
		$egg->step1;
		$egg->step2;
		$egg->step3;
	  };
	$e->next::method;
}
sub step1 {
	my($e)= @_;
	$e->finished || do {
		$e->dispatch->_start;
		$e->response->body || $e->dispatch->_action;
	  };
	$e;
}
sub step2 {
	my($e)= @_;
	$e->finished || do {
		$e->response->body || do {
			$e->view->output($e);
			$e->response->status || $e->response->status(200);
		  };
		$e->dispatch->_finish;
	  };
	$e;
}
sub step3 {
	my($e)= @_;
	$e->response->content_type
	  || $e->response->content_type($e->config->{content_type});
	$e->finalize;
	$e->output_content;
	$e;
}
sub model {
	my $e= shift;
	if ($_[0]) {
		$e->{model}{$_[0]} ||= $e->__create_comps('model', @_);
	} else {
		$e->{model}{$e->default_model}
		  ||= $e->__create_comps('model', $e->default_model);
	}
}
sub view {
	my $e= shift;
	if ($_[0]) {
		$e->{view}{$_[0]} ||= $e->__create_comps('view', @_);
	} else {
		$e->{view}{$e->default_view} ||= do {
			my $default= $e->global->
			  {VIEW_CLASS}{$e->default_view} || return 0;
			$default->new($e, $e->config->{view}{$e->default_view});
		  };
	}
}
sub __create_comps {
	my $e   = shift;
	my $type= shift || return 0;
	my $name= $e->__check_comps($type, @_) || return 0;
	my $pkg = $e->global->{uc($type).'_CLASS'}{$name} || return 0;
	$pkg->can('ACCEPT_CONTEXT')
	  ? $pkg->ACCEPT_CONTEXT($e, $e->config->{$type}{$name})
	  : $pkg->new($e, $e->config->{$type}{$name});
}
sub __check_comps {
	my $e   = shift;
	my $type= shift || return 0;
	my $name= shift || return 0;
	return $name if ($e->global->{uc($type)."_CLASS"}{$name});
	my $pkg= $e->__include_comps($name, $_[0], $type, @_);
	$pkg->setup($e, $e->config->{$type}{$name});
	return $name;
}
sub __include_comps {
	my $e      = shift;
	my $name   = shift || return 0;
	my $conf   = shift || {};
	my $type   = shift || return 0;
	my $ucType = uc($type);
	my $ucfType= ucfirst($type);
	my $ueType = uc(($type=~/^(.)/)[0]);
	my $list   = shift || $e->global->{"$ucType\_LIST"};
	my $stock  = shift || $e->global->{"$ucType\_CLASS"};
	my $base= $e->namespace;
	for my $b ("$base\::$ucfType", "$base\::$ueType", "Egg::$ucfType") {
		my $pkg= "$b\::$name";
		if ($pkg->require) {
			$e->config->{$type}{$name}= $conf;
			push @$list, $name;
			$stock->{$name}= $pkg;
		} else {
			$@=~m{^Can\'t locate $base/.+} and next;
			Egg::Error->throw($@);
		}
	}
	return $stock->{$name};
}

1;

__END__

=head1 NAME

Egg::Engine::V1 - Module concerning basic operation for Egg.

=head1 DESCRIPTION

This module is used to operate Egg basically.

As for this module, the thing replaced with the one originally developed is 
possible. 

Please note the following respect when you replace it.

=over 4

=item * startup, setup

The setup of the following value is completed with startup or setup.

  $e->global->{MODEL_LIST}
   ... It is HASH of which the value the key, and is the package name as for the model name.

  $e->global->{MODEL_CLASS}
   ... List of model name.

  $e->global->{VIEW_LIST}
   ... It is HASH of which the value the key, and is the package name as for the view name.

  $e->global->{VIEW_CLASS}
   ... List of view name. 

=item * model, view

The MODEL object and the VIEW object are returned, and it equips it with 
appropriate model and the view method.

=item * start_engine

It equips it with start_engine called from Egg::Engine.

=back

If it meets the above-mentioned requirement, the Egg::Engine subclass is made. 

It is also good to overwrite and to customize the method such as Egg::Engine of course.

The engine originally developed can be used by setting 'Engine_class'.

=head1 METHODS

=head2 startup, setup

Prior concerning the model and the view is processed.

=head2 step1

The following thing is done by processing 'step1'.

  1 ... The dispatch object is generated.
  2 ... If $e->finished is true, everything is canceled as follows.
  3 ... dispatch->_start is called.
  4 ... dispatch->_action is called.

=head2 step2

The following thing is done by processing 'step2'.

  1 ... If $e->finished is true, everything is canceled as follows.
  2 ... response->If body has defined it, only dispatch->_finish is called.
  3 ... The template is processed by $e->view->output. response->body is defined.
  4 ... response->status is set.

=head2 step3

The following thing is done by processing 'step3'.

  1 ... If response->content_type is undefined, default is set.
  2 ... $e->finalize is called. Postprocessing of plugin etc.
  3 ... $e->output_content is called. Contents are output to the client.

=head1 SEE ALSO

L<Egg::Engine>,
L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno, E<lt>mizunoE<64>bomcity.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
