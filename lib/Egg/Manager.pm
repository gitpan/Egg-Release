package Egg::Manager;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Manager.pm 240 2008-02-13 03:21:40Z lushe $
#
use strict;
use warnings;
use Carp qw/ croak /;
use base qw/ Egg::Component Egg::Base /;

our $VERSION= '3.00';

sub initialize {
	my($class, $myname)= @_;
	for (qw/ myname _default /) {
		$class->mk_classdata($_) unless $class->can($_);
	}
	$class->myname($myname);
	$class->SUPER::initialize;
}
sub setup_manager {
	my($self) = @_;
	my $class = ref($self);
	my $myname= ucfirst $self->myname;
	my $c= $self->e->config->{uc $myname} || [];
	my $p= $self->e->project_name;
	no strict 'refs';  ## no critic.
	no warnings 'redefine';
	for my $v (@$c) {
		$v= [$v, {}] unless ref($v);
		next if (! $v->[0] or $v->[0]=~m{^\-});
		my($label, $pkg);
#		if (my $label_name= $v->[1]{label_name}) {
#			$label= $label_name;
#		}
		if ($v->[0]=~m{^\+(.+)}) {
			$pkg= $1;
			$label ||= lc($pkg);
		} else {
			$pkg= "Egg::${myname}::$v->[0]";
			$label ||= lc($v->[0]);
		}
		$class->isa_register(1, $label, $pkg, $v->[1]);
		my $handler= "${pkg}::handler";
##		$handler->config($v->[1]) if $handler->can('config');
		my $p_class= "${p}::${myname}::$v->[0]";
		unless ($p_class->can('config')) {
			*{"${p_class}::config"}= sub {
				my $proto= shift;
				@_ ? $v->[1]= shift : $v->[1];
			  };
		}
		($handler->can('new') or $pkg->can('ACCEPT_CONTEXT'))
		  || die qq{$class - Constructor of '${handler}' is not found. };
	}
	$class->isa_terminator;
	$self->_default( (keys %{$self->regists})[0] || "" );
	$self->_setup($self->e);
}
sub new {
	my($class, $e)= @_;
	bless { e=> $e }, $class;
}
sub default {
	my $self= shift;
	return $self->{default}= shift if @_;
	$self->{default} ||= $self->_default
	     || croak ucfirst($self->myname). qq{ - default is empty. };
}
sub reset {
	%{$_[0]}= ( e=> ($_[1] || die q{ I want egg context. }) );
}
sub context {
	my $default= 0;
	my $self = shift;
	my $label= shift || do { $default= 1; $self->default };
	   $label= lc($label);
	$self->{"$label.$default"} ||= do {
		my $comp= $self->regists->{$label}
		   || croak ref($self). qq{ - '$label' is not set up. };
		my $conf= $comp->[2] || {};
		if (my $accept= $comp->[0]->can('ACCEPT_CONTEXT')) {
			$accept->($comp->[0], $self->e, $conf, $default, @_);
		} elsif (my $handler= "$comp->[0]::handler"->can('new')) {
			$handler->
			("$comp->[0]::handler", $self->e, $conf, $default, @_);
		} else {
			$comp->[0]->new($self->e, $conf, $default, @_);
		}
	  };
}
sub reset_context {
	my $self = shift;
	my $label= lc(shift) || croak ref($self). qq{ - I want label. };
	for (0..1) { undef($self->{"$label.$_"}) if $self->{"$label.$_"} }
	$self;
}
sub add_register {
	my($self, $load)= splice @_, 0, 2;
	my $label= lc(shift) || croak ref($self). qq{ - I want label. };
	my $attr = $self->SUPER::add_register($load, $label, @_);
	my $handler= "$attr->[0]::handler";
	$handler->config($attr->[2])
	  if ($handler->isa('Egg::Base') and ! $handler->config);
	$attr;
}
*register= \&add_register;

1;

__END__

=head1 NAME

Egg::Manager - Model manager and view manager's base classes. 

=head1 DESCRIPTION

It is a base class succeeded to by the handler of L<Egg::Manager::Model> and
L<Egg::Manager::View>.

=head1 METHODS

=head2 initialize

When starting, it initializes it.

=head2 setup_manager

Initial is set up.

The component specified by the configuration is concretely read, and it registers
in @ISA of the manager handler.

=head2 new

Constructor.

=head2 default ([LABEL_STRING])

It defaults to the component of LABEL_STRING and it sets it.

The label of the component of the default decided that LABEL_STRING is omitted
by an initial setup is returned.

=head2 reset ([PROJECT_OBJYECT])

The object is initialized. PROJECT_OBJYECT is indispensable.

=head2 context ([LABEL_STRING])

The object of the component corresponding to LABEL_STRING is returned.

When LABEL_STRING is omitted, default is used.

=head2 reset_context ([LABEL_STRING])

The constructor of the component is made to move again when the context method
is called next annulling the object of the component corresponding to LABEL_STRING
maintained with this object.

=head2 add_register ([LOAD_BOOL], [LABEL_STRING], [PACKAGE_STRING], [CONFIG])

The component is registered and to call it by the context method, it sets it up.
However, @ISA is not operated.

Require is done at the same time as registering the module of PACKAGE_STRING when
an effective value to LOAD_BOOL is passed.

LABEL_STRING gives the name to call it by the context method.

PACKAGE_STRING gives the package name of the registered component. The value of
LABEL_STRING is misappropriated when omitting it.

CONFIG can be omitted. It is preserved in the registration data when giving it.
Moreover, if "PACKAGE_STRING::handler" exists and the class has succeeded to
L<Egg::Base>, CONFIG is defined in the config method of the class.

The main of this method is add_register method of L<Egg::Component>.

=over 4

=item * Alias = register 

=back

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Component>,
L<Egg::Base>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt> 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

