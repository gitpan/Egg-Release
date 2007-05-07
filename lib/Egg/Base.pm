package Egg::Base;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Base.pm 96 2007-05-07 21:31:53Z lushe $
#

=head1 NAME

Egg::Base - General-purpose base class for Egg.

=head1 SYNOPSIS

  use base qw/Egg::Base/;
  
  # A peculiar configuration to the class is set.
  __PACKAGE__->config( ... );
  
  # Global HASH peculiar to the project is set.
  __PACKAGE__->global( ... );
  
  my $self= __PACKAGE__->new([egg_object]);
  
  # The parameter is set to the object.
  $self->param( in_param => 'in_value' );
  
  # The class name under operation is obtained.
  print $self->namespace;
  
  # The error message is set.
  $self->error('internal error.');
  
  # The error is checked.
  if (my $err= $self->errstr) { die $err }

=head1 DESCRIPTION

Some methods of the fixed form are offered to the class that succeeds to this
module.

=cut
use strict;
use warnings;
use Class::C3;
use UNIVERSAL::require;
use base qw/Class::Data::Inheritable/;
use Carp qw/croak/;

our $VERSION = '2.00';

=head1 METHODS

=head2 mk_classdata ( [METHOD] )

It is a method offered by L<Class::Data::Inheritable>.

see L<Class::Data::Inheritable>

=cut

__PACKAGE__->mk_accessors(qw/ e parameters /);

{
	no strict 'refs';  ## no critic

=head2 config ( [HASH_REF] )

Passed HASH_REF is set as a configuration.

=cut
	sub config {
		my $class= shift;
		my $base = ref($class) || $class || return 0;
		return ${"${base}::__GLOBAL_CONDIG"} || {} unless @_;
		my $conf= ${"${base}::__GLOBAL_CONDIG"}= $_[1] ? {@_}: ($_[0] || {});
		my $config;
		if ($base=~m{^([^\:]+)\:.+} and ($config= $1->config)) {
			$class->replace_deep($config, $conf);
		}
		$conf;
	}

=head2 global ( [HASH_REF] )

It sets it as a variable that can use passed HASH_REF globally in the project.
* It is necessary to be called from the class including the project name.

=cut
	sub global {
		my $class= ref($_[0]) || $_[0] || return 0;
		   $class=~/^([^\:]+)/;
		return ${"$1\::__GLOBAL_HASH"} ||= {};
	}

=head2 mk_accessors ( [ACCESSOR_LIST] )

It is a method offered by L<Class::Accessor::Fast>.

=cut
	no warnings 'redefine';
	sub mk_accessors {
		my $class= ref($_[0]) || $_[0] || return 0;
		for my $field (@_) {
			*{"${class}::$field"}= sub {
				my $self= shift;
				@_ ? $self->{$field}= shift : $self->{$field};
			  };
		}
	}

  };

=head2 new ( [PROJECT_OBJECT], [PARAM] )

Constructor.

It can access PROJECT_OBJECT with $self-E<gt>e.

It can access PARAM with parameters.

=cut
sub new {
	my $class= shift;
	my $e    = shift || "";
	my $param= shift || {};
	bless { e=> $e, parameters=> $param }, $class;
}

=head2 e

Accessor to project object.

  $self->e;

=head2 param ( [KEY], [VALUE] )

This moves a general param similar method.

If the argument is omitted, the parameter key list that has been set is 
returned.

If KEY is passed, the value of the corresponding parameter is returned.

If KEY and VALUE are passed, the value is set in the corresponding parameter.

=cut
sub param {
	my $self= shift;
	return keys %{$self->parameters} unless @_;
	my $key = shift;
	@_ ? $self->parameters->{$key}= shift
	: (defined($self->parameters->{$key}) ? $self->parameters->{$key}: "");
}

=head2 parameters

The HASH reference of the parameter is returned.

=over 4

=item * Alias: params

=back

=cut
*params= \&parameters;

=head2 namespace

The class name of the object is returned while operating.
It is the same as 'ref($self)'.

=over 4

=item * Alias: myname

=back

=cut
sub namespace { ref($_[0]) || $_[0]  }
*myname= \&namespace;

=head2 uc_namespace

The result of doing $self-E<gt>namespace in uc is returned.

=over 4

=item * Alias: uc_myname

=back

=cut
sub uc_namespace { uc($_[0]->namespace) }
*uc_myname= \&uc_namespace;

=head2 lc_namespace

The result of doing $self-E<gt>namespace in lc is returned.

=over 4

=item * Alias: lc_myname

=back

=cut
sub lc_namespace { lc($_[0]->namespace) }
*lc_myname= \&lc_namespace;

=head2 include ( [PACKAGE_NAME] )

PACKAGE_NAME is done in require and registered.

  __PACKAGE__->include( 'Include::Package' );

=cut
sub include {
	my $class= shift;
	my $pkg  = shift || return 0;
	my $base = ref($class) || $class;
	$pkg->require or croak $@;
	my $inc= $class->global->{"include_package_${base}"} ||= [];
	push @$inc, $pkg;
}

=head2 include_packages

The list of the package read by 'include' method is returned by the ARRAY reference.
An empty ARRAY reference returns to anything when there is no registration.

  my $include_package= $self->include_packages->[0] || 'none.';

=cut
sub include_packages {
	my $base= ref($_[0]) || $_[0];
	$_[0]->global->{"include_package_${base}"} || [];
}

=head2 replace_deep ( [PARAM_HASH_REF], [HASH or ARRAY etc] )

It does in the data such as passed HASH and ARRAY and $self->replace is
recurrently done.

=cut
sub replace_deep {
	my $self = shift;
	my $param= shift || croak q{ I want base parameter. };
	my $value= defined($_[0]) ? $_[0]: return "";
	if (my $type= ref($value)) {
		if ($type eq 'HASH') {
			while (my($k, $v)= each %$value) {
				ref($v) ? $self->replace_deep($param, $v)
				        : $self->replace($param, \$v);
				$value->{$k}= $v;
			}
		} elsif ($type eq 'ARRAY') {
			for (@$value) {
				ref($_) ? $self->replace_deep($param, $_)
				        : $self->replace($param, \$_);
			}
		} else {
			return $value;
		}
	} else {
		return $self->replace(\$value);
	}
}

=head2 replace ( [PARAM_HASH_REF], [VALUE] )

It replaces it with the value to which the place of the following descriptions
of passed VALUE is returned by PARAM_HASH_REF.

  < $e.param_name >  or < $e.foo.baa.param_name >
  
  * It is enclosed with < > and an inside character string is $e. The description
    that starts is substituted.
  * If the name of the parameter is delimited by '.', the hierarchy is expressible.
  * The CODE reference is appreciable in the parameter value of the object.

* The value of VALUE should be SCALAR that is the SCALAR reference or usual.

=cut
sub replace {
	my $self = shift;
	my $param= shift || confess(q{ I want base parameter. });
	my $str  = defined($_[0]) ? shift: return "";
	my $text;
	if (my $type= ref($str)) {
		return $str unless $type eq 'SCALAR';
		$text= $str;
	} else {
		$text= \$str;
	}
	return "" unless defined($$text);
	$$text=~s{([\\]?)< *\$e\.([\w\d\.]+) *>}
	   [ $1 ? "<\$e.$2>": __replace($2, $self, $param, @_) ]sge;
	$$text;
}
sub __replace {
	my @part= split /\.+/, shift;
	my $v;
	eval "\$v= \$_[1]->{". join('}{', @part)."}";  ## no critic
	defined($v) ? do { ref($v) eq 'CODE' ? $v->(@_): $v }: "";
}

sub _setup    { @_ }
sub _prepare  { 0 }
sub _action   { 0 }
sub _finalize { 0 }

=head2 error ( [ERROR_MESSAGE] )

The passed error message is maintained.

If ERROR_MESSAGE is omitted and the error message has defined it, the ARRAY
reference is returned.

=cut
sub error {
	my $self= shift;
	if ($_[0]) {
		$self->{error} ||= [];
		my $error= ref($_[0]) eq 'ARRAY' ? $_[0]: [@_];
		croak join "\n", @$error unless ref($self);
		splice @{$self->{error}}, scalar(@{$self->{error}}), 0, @$error;
	} elsif (defined($_[0])) {
		$self->{error}= undef;
	}
	$self->{error} || 0;
}

=head2 errstr

If $self-E<gt>error has defined it, the error message made a changing line
delimitation is returned.

If the receiving side is ARRAY, usual ARRAY is returned.

=cut
sub errstr {
	my($self)= @_;
	return 0 unless $self->{error};
	wantarray ? @{$self->{error}}: join("\n", @{$self->{error}});
}

=head1 SEE ALSO

L<Class::C3>
L<UNIVERSAL::require>
L<Class::Accessor::Fast>
L<Class::Data::Inheritable>
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
