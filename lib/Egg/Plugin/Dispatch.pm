package Egg::Plugin::Dispatch;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Dispatch.pm 147 2007-05-14 02:24:16Z lushe $
#
use strict;
use warnings;
use Carp qw/croak/;

our $VERSION = '2.01';

=head1 NAME

Egg::Plugin::Dispatch - It is a base class for Dispatch.

=head1 SYNOPSIS

  use base qw/Egg::Plugin::Dispatch/;
  
  __PACKAGE__->run_modes( ... );
  
  __PACKAGE__->default_mode( ... );
  
  $e->dispatch;

=head1 DESCRIPTION

This is a base class for the Dispatch plugin.

To do the function as Dispatch of Egg, necessary minimum method is offered.

=head1 EXPORT FUNCTION

It is a function compulsorily exported by the controller of the project.

=cut
sub _import {
	my($project)= @_;
	no strict 'refs';  ## no critic
	no warnings 'redefine';

=head2 code ( [PACKAGE_NAME], [METHOD_NAME] )

PACKAGE_NAME is read, and the code reference of METHOD_NAME is returned.

Please give PACKAGE_NAME the module name since the project name.

Using it because of the setting of run_modes etc. is convenient for this method.

  # The CODE reference of the content method of MyApp::Dispatch is set.
  # * In this case, ($dispatch, $e) extends to the content method.
  package MyApp;
  .......
  ...
  __PACKAGE__->egg_startup(
    .......
    ...
    content => code( Dispatch => 'content' ),
    );

  # When using it in the code. * An arbitrary argument is passed.
  $e->code( Dispatch => 'content' )->($e, ... args );

=cut
	*{"${project}::code"}= sub {
		shift if ref($_[0]);
		my $pkg= shift || croak q{ I want include package name. };
		   $pkg= "${project}::$pkg";
		my $method= shift || croak q{ I want method name. };
		$pkg->require or die $@;
		$pkg->can($method) || croak qq{ '$method' method is not found. };
	  };

	$project->next::method;
}

=head1 METHODS

=head2 run_modes ( [RUN_MODE_HASH] )

Received RUN_MODE_HASH is set in the global variable of the project.

RUN_MODE_HASH set to omit RUN_MODE_HASH is returned.

  __PACKAGE__->run_modes (
    _default => sub {},
    hoge     => sub { ... },
    );

=cut
sub run_modes {
	my $class= shift;
	return $class->global->{dispatch_run_modes} || 0 unless @_;
	my $modes= ref($_[0]) ? $_[0]: {@_};
	$class->global->{dispatch_run_modes}=
	   $class->_run_modes_check($modes, $class);
}

=head2 default_mode ( [DEFAULT_MODE] )

Received DEFAULT_MODE is set in the global variable of the project.

* '_' is put when there is no first '_' of the character string.

DEFAULT_MODE set to omit DEFAULT_MODE is returned.

* Default is '_default'.

  __PACKAGE__->default_mode( '_index' )

=over 4

=item * Alias: start_mode

=back

=cut
sub default_mode {
	my $g= shift->global;
	return $g->{dispatch_default_mode} ||= '_default' unless @_;
	my $default= shift || return 0;
	$g->{dispatch_default_mode}= $default=~m{^_} ? $default: "_$default";
}
*start_mode= \&default_mode;

=head2 mode_param ( [MODE_PARAM_NAME] )

The parameter name to decide the action of dispatch is setup.

  __PACKAGE__->mode_param( 'mode' );

* If the access control of the URI base is done, it is not necessary to set
  it especially.

=cut
{
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	sub mode_param {
		my $class= shift;  return 0 if ref($class);
		my $pname= shift || croak(q{ I want param name. });
		my $uc_class= uc($class);
		*{"$class\::_get_mode"}= sub {
			$ENV{"$uc_class\_REQUEST_PARTS"}
			  || $_[0]->request->param($pname)
			  || return(undef);
		  };
		$class;
	}
  };

=head2 dispatch

The exception is generated when there is no dispatch method in the succession
class.

=cut
sub dispatch  { die q{ Absolute method is not found. } }

sub _get_mode        { 0 }
sub _run_modes_check { $_[1] }


package Egg::Plugin::Dispatch::handler;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

=head1 HANDLER METHODS

Basic method for main body of dispatch.

=head2 e

Accessor to Egg object.

=head2 stash

Accessor to $e-E<gt>stash. * However, contents are the HASH references.

=head2 run_modes

Accessor to HASH reference set with run_modes.

=head2 action

Accessor for storage of list of matched run_modes key.

* The thing that is the ARRAY reference is hoped for without fail.

=head2 label

Accessor for label and list storage picked up from action.

* The thing that is the ARRAY reference is hoped for without fail.

=head2 page_title

Accessor that assumes thing that label or key to action finally matched is put.

=head2 default_mode

Accessor to value set in default_mode.

=head2 default_name

The value of 'template_default_name' of $e-E<gt>config is returned.

=cut
__PACKAGE__->mk_accessors(qw{
  e stash config run_modes
  action mode label page_title default_mode default_name
  });

=head2 new

Constructor.

  shift->SUPER::new(@_);

=cut
sub new {
	my($class, $e)= @_;
	my $self= bless {
	  e      => $e,
	  stash  => $e->stash,
	  config => $e->config,
	  label  => [],
	  action => [],
	  page_title  => "",
	  run_modes   => ($e->run_modes || {}),
	  default_name=> $e->config->{template_default_name},
	  default_mode=> $e->default_mode,
	  }, $class;
	$self->_initialize;
}

=head2 target_action

The URI passing to decided action is assembled and it returns it.

=cut
sub target_action {
	my($self)= @_;
	my $action= $self->action || return "";
	@$action ? '/'. join('/', @$action): "";
}

=head2 _start

Method that is called from Egg for the most much correspondence to hook for
the first dispatch.

=cut
sub _start  {
	my($self)= @_;
	1;
}

=head2 _action

Method of favorite that is called from Egg for dispatch processing.

=cut
sub _action {
	my($self)= @_;
	1;
}

=head2 _finish

Method that is called from Egg for the most much correspondence to hook for
the last dispatch.

=cut
sub _finish {
	my($self)= @_;
	1;
}

=head2 reset

Alias to '_initialize' method.

* Any method of '_initialize' of this module is not done.

=cut
*reset= \&_initialize;
sub _initialize   { $_[0] }

=head2 _example_code

It is a method that calls from Egg::Helper::BlankPage.

For contents offer of sample Dispatch published in sample page.

=cut
sub _example_code { 'none.' }

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 2007 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
